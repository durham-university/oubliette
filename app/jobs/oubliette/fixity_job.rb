module Oubliette
  class FixityJob
    include Jobduct::ChannelJob
    include DurhamRails::Channels::ChannelBase
    include DurhamRails::Channels::WithJobContainer
    
    request_reader :fixity_mode, default: [:fedora, :ingestion] do |val| Array.wrap(val).map(&:to_sym) end
    request_reader :max_fail_count, default: 10
    request_reader :file_limit, default: 500
    request_reader :time_limit, default: 30
    
    def default_job_container_category
      :oubliette
    end
        
    def run
      log!("Starting #{fixity_mode.join(' and ')} fixity check of preserved files")
      log!("File limit #{file_limit}") if file_limit.present? && file_limit>0
      log!("Time limit #{time_limit} days") if time_limit.present? && time_limit>0
      time_limit_seconds = time_limit.present? ? time_limit*1.day : 0
      now = DateTime.now.to_i
      fail_count = 0
      check_count = 0
      aborted = false
      # Due to the large batch size and problems with .limit in ActiveFedora and RSolr,
      # it's better to get files first from Solr even though they need to be then
      # retrieved individually from Fedora.
      files = PreservedFile.all.from_solr!.order('check_date_dtsi asc', 'ingestion_date_dtsi asc')
      files = files.limit(file_limit) unless file_limit.nil? || file_limit <= 0
      files.each do |pf_solr|
        return process_halt! if halted?
        pf = PreservedFile.find(pf_solr.id)
        if time_limit_seconds > 0 && pf.check_date.present? && now-(pf.check_date.to_i) < time_limit_seconds
          log!(:info, "Reached time limit, stopping")
          break
        end
        # Setting files.limit above doesn't appear to actually limit the query properly. A bug in RSolr or ActiveFedora.
        break if file_limit.present? && file_limit>0 && check_count>=file_limit
        
        actor = Oubliette::FixityActor.new(pf,nil,{})
        actor.instance_variable_set(:@log, log)
        pass = true
        pass &= actor.fedora_fixity! if fixity_mode.include?(:fedora)
        pass &= actor.ingestion_fixity! if fixity_mode.include?(:ingestion)
        actor.finish
        
        check_count += 1
        fail_count += 1 unless pass
        if max_fail_count > 0 && fail_count >= max_fail_count
          aborted = true
          log!(:error, "Max fail count #{max_fail_count} reached. Aborting fixity check of remaining files.")
          break
        end
      end
      log!("Finished fixity checking preserved files. #{check_count} files checked, #{fail_count} errors.") unless aborted
    end
    
  end
end