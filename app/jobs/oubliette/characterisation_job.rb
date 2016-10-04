module Oubliette
  class CharacterisationJob
    include DurhamRails::Jobs::JobBase
    include Oubliette::OublietteJob
    include DurhamRails::Jobs::WithResource
        
    def run_job
      actor = Oubliette::CharacterisationActor.new(resource)
      actor.instance_variable_set(:@log, log)
      actor.set_characterisation
    end
  end
end