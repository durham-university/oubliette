require 'rails_helper'

RSpec.describe Oubliette::CharacterisationJob do

  let(:file) { FactoryGirl.create(:preserved_file, :with_file) }
  let(:request) { {resource_id: file.id} }
  let(:channel) { Oubliette::CharacterisationJob.new_channel(request) }
  let(:job) { Oubliette::CharacterisationJob.new(channel) }  
  let!(:actor) { Oubliette::CharacterisationActor.new(file) }
  
  describe "#run" do
    before {
      expect(Oubliette::CharacterisationActor).to receive(:new) do |resource|
        expect(resource.id).to eql(file.id)
        actor
      end      
    }    
    let(:characterisation_doc) { double('characterisation doc', to_s: 'characterisation doc') }
    it "runs characterisation actor" do
      expect(actor).to receive(:characterisation).and_return(characterisation_doc)
      job.run
      file.reload
      expect(file.characterisation.content).to eql('characterisation doc')
    end
  end

end