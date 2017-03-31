module Oubliette
  class FixityJob
    include DurhamRails::Jobs::JobBase
    include Oubliette::OublietteJob
    include DurhamRails::Jobs::WithJobContainer
    
    attr_accessor :fixity_mode, :max_fail_count, :file_limit, :time_limit
    
    # fixity_mode can be :fedora, :ingestion or an array containing both
    def initialize(params={})
      self.fixity_mode = Array.wrap(params.fetch(:fixity_mode, [:fedora, :ingestion]))
      self.max_fail_count = params.fetch(:max_fail_count, 10)
      self.file_limit = params.fetch(:file_limit, 50)
      self.time_limit = params.fetch(:time_limit, 30)
      super(params)
    end
    
    def dump_attributes
      super + [:fixity_mode, :max_fail_count, :file_limit, :time_limit]
    end
    
    def default_job_container_category
      :oubliette
    end
        
    def run_job
      log!("Starting #{fixity_mode.join(' and ')} fixity check of preserved files")
      log!("File limit #{file_limit}") if file_limit.present? && file_limit>0
      log!("Time limit #{time_limit} days") if time_limit.present? && time_limit>0
      time_limit_seconds = time_limit.present? ? time_limit*1.day : 0
      now = DateTime.now.to_i
      fail_count = 0
      check_count = 0
      aborted = false
      files = PreservedFile.all.order('check_date_dtsi asc', 'ingestion_date_dtsi asc')
      files = files.limit(file_limit) unless file_limit.nil? || file_limit <= 0
      files.each do |pf|
        if time_limit_seconds > 0 && pf.check_date.present? && now-(pf.check_date.to_i) < time_limit_seconds
          log!(:info, "Reached time limit, stopping")
          break
        end
        
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