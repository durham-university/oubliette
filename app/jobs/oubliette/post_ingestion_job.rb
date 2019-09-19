module Oubliette
  class PostIngestionJob
    include Jobduct::ChannelJob
    include DurhamRails::Channels::ChannelBase
    include DurhamRails::Channels::WithResource
    include Jobduct::WithStates
    
    request_reader :fixity_mode, default: [:fedora, :ingestion] do |val| Array.wrap(val).map(&:to_sym) end
    request_reader :content_path

    job_state :fixity, on_success: [:do_characterisation]
    job_state :characterisation, on_success: [:job_finished]
        
    def run
      do_fixity
    end

    def do_fixity(callback=nil)
      self.state = 'fixity'
      local_call('fixity', {binding_key: 'fixity_single', fixity_mode: fixity_mode, resource: resource})
      true
    end

    def do_characterisation(callback=nil)
      self.state = 'characterisation'
      local_call('characterisation', {binding_key: 'characterisation', resource: resource, content_path: content_path})
      true
    end
    
  end
end