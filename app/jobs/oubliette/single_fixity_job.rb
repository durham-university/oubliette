module Oubliette
  class SingleFixityJob
    include Jobduct::ChannelJob
    include DurhamRails::Channels::ChannelBase
    include DurhamRails::Channels::WithResource
    
    request_reader :fixity_mode, default: [:fedora, :ingestion] do |val| Array.wrap(val).map(&:to_sym) end
    request_reader :fedora_retry_count, default: 10
        
    def run
      log!("Starting #{fixity_mode.join(' and ')} fixity check")
      
      actor = Oubliette::FixityActor.new(resource,nil,{fedora_retry_count: fedora_retry_count})
      actor.instance_variable_set(:@log, log)
      pass = true
      pass &= actor.fedora_fixity! if fixity_mode.include?(:fedora)
      pass &= actor.ingestion_fixity! if fixity_mode.include?(:ingestion)
      actor.finish
        
      log!("Fixity checking #{pass ? "passed" : "failed"}")
    end
    
  end
end