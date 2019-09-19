module Oubliette
  class CharacterisationActor < Oubliette::BaseActor
    include DurhamRails::Actors::ShellRunner
    include DurhamRails::Actors::FitsRunner
    
    def characterisation
      log!("Characterising #{model_object.id}")

      path = if @attributes[:content_path].present? && File.exists?(@attributes[:content_path])
        # First check if we were provided with a path to the file
        @attributes[:content_path]
      elsif model_object.content.instance_variable_get(:@content).respond_to?(:path)
        # if content has just been set to a file object, then we can avoid having
        # to make a temporary file
        model_object.content.instance_variable_get(:@content).path
      else
        # have to get content from Fedora
        nil
      end

      (fits_output, error_out, exit_code) = if path.present?
        log!(:debug,"Using existing file at #{path}")
        run_fits(path)
      else
        log!(:debug,"Creating and using temporary file")
        run_fits_io(model_object.content_io, model_object.content.original_name || 'fits_temp')
      end

      unless exit_code == 0
        log!(:error, "Unable to run fits: #{error_out}")
        return nil
      end
      fits_output
    end
    
    def set_characterisation(save_model=true)
      characterisation_doc = characterisation
      return false unless characterisation_doc
      model_object.characterisation.content = characterisation_doc.to_s
      model_object.save if save_model
    end
  end
end