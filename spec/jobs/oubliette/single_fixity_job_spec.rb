require 'rails_helper'

RSpec.describe Oubliette::SingleFixityJob do

  let(:preserved_file) { FactoryGirl.create(:preserved_file, :with_file) }

  let(:job) { Oubliette::SingleFixityJob.new(resource: preserved_file, fixity_mode: [:fedora, :ingestion]) }

  describe "marshalling" do
    let(:job) { Oubliette::SingleFixityJob.new(resource: preserved_file, fixity_mode: [:fedora, :ingestion]) }
    let(:serial) { Marshal.dump(job) }
    let(:deserial) { Marshal.load(serial) }
    it "preserves variables" do
      expect(deserial.fixity_mode).to eql([:fedora, :ingestion])
      expect(deserial.resource_id).to be_present
    end
  end

  describe "#run_job" do
    it "checks preserved files and notes errors" do
      expect(preserved_file.preservation_log.content).to be_nil
      expect(preserved_file.check_date).to be_nil
      preserved_file.content.content='moo' # cause fixity error
      preserved_file.content.save
      expect_any_instance_of(Oubliette::FixityActor).to receive(:notify_fixity_error)
      job.run_job
      preserved_file.reload
      expect(preserved_file.status).to eql("error")
      expect(preserved_file.preservation_log.content).to be_present
      expect(preserved_file.check_date).to be_present
    end
    
    it "checks preserved files and marks passing" do
      expect(preserved_file.preservation_log.content).to be_nil
      expect(preserved_file.check_date).to be_nil
      expect_any_instance_of(Oubliette::FixityActor).not_to receive(:notify_fixity_error)
      job.run_job
      preserved_file.reload
      expect(preserved_file.status).to eql("passing")
      expect(preserved_file.preservation_log.content).to be_present
      expect(preserved_file.check_date).to be_present
    end
  end

end