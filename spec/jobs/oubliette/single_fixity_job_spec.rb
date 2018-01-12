require 'rails_helper'

RSpec.describe Oubliette::SingleFixityJob do

  let(:preserved_file) { FactoryGirl.create(:preserved_file, :with_file) }

  let(:request) { {resource_id: preserved_file.id, fixity_mode: [:fedora, :ingestion]} }
  let(:channel) { Oubliette::SingleFixityJob.new_channel(request) }
  let(:job) { Oubliette::SingleFixityJob.new(channel) }  
  let!(:actor) { Oubliette::FixityActor.new(preserved_file) }

  describe "#run" do
    before {
      expect(Oubliette::FixityActor).to receive(:new) do |resource|
        expect(resource.id).to eql(preserved_file.id)
        actor
      end      
    }        
    it "checks preserved files and notes errors" do
      expect(preserved_file.preservation_log.content).to be_nil
      expect(preserved_file.check_date).to be_nil
      preserved_file.content.content='moo' # cause fixity error
      preserved_file.content.save
      expect(actor).to receive(:notify_fixity_error)
      job.run
      preserved_file.reload
      expect(preserved_file.status).to eql("error")
      expect(preserved_file.preservation_log.content).to be_present
      expect(preserved_file.check_date).to be_present
    end
    
    it "checks preserved files and marks passing" do
      expect(preserved_file.preservation_log.content).to be_nil
      expect(preserved_file.check_date).to be_nil
      expect(actor).not_to receive(:notify_fixity_error)
      job.run
      preserved_file.reload
      expect(preserved_file.status).to eql("passing")
      expect(preserved_file.preservation_log.content).to be_present
      expect(preserved_file.check_date).to be_present
    end
  end

end