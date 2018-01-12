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
    it "runs characterisation actor" do
      expect(actor).to receive(:set_characterisation)
      job.run
    end
  end

end