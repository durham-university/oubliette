# The main purpose of this is to run a one-off batch process to fix issues in early
# Adlib CD Batch ingests. Specifically it addresses two problems. 
# 1) Invalid TIFF files ended up in Oubliette. The TiffFixer correctly fixed them
#    but instead of the fixed version, the original was ingested. This will run the 
#    TiffFixer again if the characterisation document states that the file is invalid.
# 2) Files went in as text/plain instead of image/tiff. If TiffFixer is run then this 
#    is fixed as well, if the TIFF is valid then a separate procedure is run which 
#    fixes the content type only.
#
# There are no specs so it is possible that it will not function correctly in the future.
# Run separate tests before using in production.

module Oubliette
  class FileFixer < Oubliette::BaseActor

    def dry_run?
      attributes.fetch(:dry_run, false)
    end

    def fix_adlib_files
      total_count = 0
      changed_count = 0
      Oubliette::PreservedFile.where(tag: 'adlib').each do |file|
        changed = process_file(file)
        total_count += 1
        changed_count += 1 if changed
        break if log.errors?
      end
      log!("Checked #{total_count} files. Changed #{changed_count} files.")
    end

    def process_file(file=nil)
      file ||= model_object
      log!(:debug,"Checking file #{file_label(file)}")

      changed = false
      if !tiff_valid?(file)
        changed = fix_tiff(file)
      elsif file.content.mime_type != 'image/tiff'
        changed = set_mime_type(file,'image/tiff')
      end
      return false if log.errors?
      if changed
        return true
      else
        log!(:debug, "File ok #{file_label(file)}")
      end
      false
    end

    def save_file(file)
      # keep file saves in this so we can easily do dry runs and logging
      unless dry_run?
        log!("Saving file #{file_label(file)}")
        file.save
      else
        log!("Would save file #{file_label(file)} but in dry run mode.")
      end
    end

    def tiff_valid?(file=nil, xml=nil)
      file ||= model_object
      xml ||= characterisation_xml(file)
      return false unless xml.present?
      xml.xpath('/xmlns:fits/xmlns:filestatus/xmlns:valid[@toolname="Jhove"]/text()').first.to_s == 'true'
    end

    def fix_tiff(file) # PreservedFile
      label = file_label(file)

      if !tiff_valid?(file)
        content_path = download_file(file)
        return false unless content_path.present?
        begin
          log!("File #{label}, not valid, fixing")
          open_file = File.open(content_path,'r+b')

          fixer = DurhamRails::TiffFixer.new(open_file)
          fixer.log_out = FixerLogger.new(self)
          fixer.create_patch
          fixer.uncompress
          unless fixer.patch_present?
            log!(:error, "Unable to create patch for #{label}")
            return false
          end
          fixer.apply_patch
          fixer.cleanup
          open_file.close

          char_actor = Oubliette::CharacterisationActor.new(file, user, content_path: content_path)
          char_actor.instance_variable_set(:@log, log)
          new_characterisation = char_actor.characterisation
          unless new_characterisation.present?
            log!(:error, "Unable to create new characterisation for #{label}")
            return false
          end
          
          unless tiff_valid?(file, new_characterisation)
            log!(:error, "Fixed file for #{label} still not valid")
            return false
          end

          open_file = File.open(content_path)
          md5 = calculate_md5(open_file) .tap do |_| open_file.rewind end
          original_name = file.content.original_name
          file.note = [file.note.presence, "Original file failed validation tests. Automatic fix applied."].compact.join(" ")
          file.ingestion_checksum = "md5:#{md5}"
          file.content.content = open_file
          file.content.mime_type = 'image/tiff'
          file.content.original_name = original_name
          file.characterisation.content = new_characterisation.to_s

          save_file(file)
          true
        ensure
          File.unlink(content_path) if content_path.present? && File.exists?(content_path)
        end
      end
    end

    def file_label(file) # PreservedFile
      "#{file.title} (#{file.id})"
    end

    def download_file(file) # PreservedFile
      tempfile = Tempfile.open(['file_fixer_original',file.content.original_name], Dir.tmpdir, binmode: true)
      file.content.stream.each do |chunk|
        tempfile.write(chunk)
      end
      tempfile.close
      if File.size(tempfile.path) <= 0
        log!(:error, "Unable to download file #{file_label(file)}")
        return nil
      end
      tempfile.path
    end
  
    def characterisation_xml(file)
      label = file_label(file)
      characterisation = file.characterisation.try(:content)
      if characterisation.present?
        Nokogiri::XML(characterisation)
      else
        log!(:warning, "No characterisation present for #{label}. Running characterisation")
        a = Oubliette::CharacterisationActor.new(file, user)
        a.instance_variable_set(:@log, log)
        a.set_characterisation(false)
        characterisation = file.characterisation.try(:content)
        if characterisation.present?
          Nokogiri::XML(characterisation)
        else
          log!(:error, "Couldn't generate characterisation for #{label}")
          nil
        end
      end
    end

    def calculate_md5(file) # IO object
      digest = Digest::MD5.new
      buf = ""
      while file.read(16384, buf)
        digest.update(buf)
      end
      digest.hexdigest
    end

    def set_mime_type(file, mime_type) # PreservedFile, mime_type
      if file.content.mime_type != mime_type
        label = file_label(file)
        log!(:info, "Incorrect mime type in #{label}, fixing.")
        content_path = download_file(file)
        begin
          # It appears impossible to just change the mime_type, even by doing a direct sparql update.
          # The only working solution is to update content to something else, save, and then set it
          # back to what it was along with the mime_type update.
          original_name = file.content.original_name
          file.content.content = ""
          save_file(file)
          file.content.content = File.open(content_path)
          file.content.mime_type = mime_type
          file.content.original_name = original_name
          save_file(file)
          return true
        rescue StandardError => e
          # In case there's an error, preserve the temporary file. The first save which erased
          # the content might have worked while the second didn't which would leave the content
          # erased.
          content_path = nil # this prevents unlinking
          log!(:error, "Error saving file #{file_label}. Content may have been erased. Copied content to #{content_path}", e)
        ensure
          File.unlink(content_path) if content_path.present? && File.exists?(content_path)
        end
      end
      false
    end

    class FixerLogger
      MESSAGE_LEVELS=[:debug, :debug, :info, :warn, :error]
      def initialize(actor)
        @actor = actor
      end
      def log(message, level)
        @actor.log!(MESSAGE_LEVELS[level], message)
      end
    end

  end
end