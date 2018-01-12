module Oubliette
  class CharacterisationJob
    include Jobduct::ChannelJob
    include DurhamRails::Channels::ChannelBase
    include DurhamRails::Channels::WithResource
        
    def run
      actor = Oubliette::CharacterisationActor.new(resource)
      actor.instance_variable_set(:@log, log)
      actor.set_characterisation
    end
  end
end