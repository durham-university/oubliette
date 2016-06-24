module Oubliette
  class FixityJob
    include DurhamRails::Jobs::JobBase
    include Oubliette::OublietteJob
    include DurhamRails::Jobs::WithJobContainer
    
    attr_accessor :fixity_mode, :max_fail_count
    
    # fixity_mode can be :fedora, :ingestion or an array containing both
    def initialize(params={})
      self.fixity_mode = Array.wrap(params.fetch(:fixity_mode, [:fedora, :ingestion]))
      self.max_fail_count = params.fetch(:max_fail_count, 10)
      super(params)
    end
    
    def dump_attributes
      super + [:fixity_mode, :max_fail_count]
    end
    
    def default_job_container_category
      :oubliette
    end
        
    def run_job
      log!("Starting #{fixity_mode.join(' and ')} fixity check of all preserved files")
      fail_count = 0
      aborted = false
      PreservedFile.find_each do |pf|
        actor = Oubliette::FixityActor.new(pf,nil,{})
        actor.instance_variable_set(:@log, log)
        pass = true
        pass &= actor.fedora_fixity! if fixity_mode.include?(:fedora)
        pass &= actor.ingestion_fixity! if fixity_mode.include?(:ingestion)
        actor.finish
        
        fail_count += 1 unless pass
        if max_fail_count > 0 && fail_count >= max_fail_count
          aborted = true
          log!(:error, "Max fail count #{max_fail_count} reached. Aborting fixity check of remaining files.")
          break
        end
      end
      log!("Finished fixity checking all preserved files") unless aborted
    end
    
  end
end