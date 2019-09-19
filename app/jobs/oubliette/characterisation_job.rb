module Oubliette
  class CharacterisationJob
    include Jobduct::ChannelJob
    include DurhamRails::Channels::ChannelBase
    include DurhamRails::Channels::WithResource
    include DurhamRails::Retry

    request_reader :content_path
    
    def run
      actor = Oubliette::CharacterisationActor.new(resource, user_key, {content_path: content_path})
      actor.instance_variable_set(:@log, log)

      # This is basically actor.set_chanacterisation but with retry added for save
      characterisation_doc = actor.characterisation
      return unless characterisation_doc # actor should have logged error already

      self.retry(retry_log(self, :warning, "saving characterisation", increasing_delay)) do
        resource.characterisation.content = characterisation_doc.to_s
        resource.save
      end
    end
  end
end