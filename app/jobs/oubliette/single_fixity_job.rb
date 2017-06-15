module Oubliette
  class SingleFixityJob
    include DurhamRails::Jobs::JobBase
    include Oubliette::OublietteJob
    include DurhamRails::Jobs::WithResource
    
    attr_accessor :fixity_mode
    
    # fixity_mode can be :fedora, :ingestion or an array containing both
    def initialize(params={})
      self.fixity_mode = Array.wrap(params.fetch(:fixity_mode, [:fedora, :ingestion]))
      super(params)
    end
    
    def dump_attributes
      super + [:fixity_mode]
    end
    
    def run_job
      log!("Starting #{fixity_mode.join(' and ')} fixity check")
      
      actor = Oubliette::FixityActor.new(resource,nil,{})
      actor.instance_variable_set(:@log, log)
      pass = true
      pass &= actor.fedora_fixity! if fixity_mode.include?(:fedora)
      pass &= actor.ingestion_fixity! if fixity_mode.include?(:ingestion)
      actor.finish
        
      log!("Fixity checking #{pass ? "passed" : "failed"}")
    end
    
  end
end