require 'rails_helper'

RSpec.describe Oubliette::FixityJob do

  let(:preserved_file1) { FactoryGirl.create(:preserved_file, :with_file) }
  let(:preserved_file2) { FactoryGirl.create(:preserved_file, :with_file) }

  let(:job) { Oubliette::FixityJob.new(fixity_mode: [:fedora, :ingestion], max_fail_count: 20) }

  describe "marshalling" do
    let(:serial) { Marshal.dump(job) }
    let(:deserial) { Marshal.load(serial) }
    it "preserves fixity_mode" do
      expect(deserial.fixity_mode).to eql([:fedora, :ingestion])
      expect(deserial.max_fail_count).to eql(20)
      expect(deserial.resource_id).to be_present
    end
  end

  describe "#run_job" do
    it "checks all preserved files" do
      preserved_file1 ; preserved_file2 # create by referencing
      expect(preserved_file1.preservation_log.content).to be_nil
      preserved_file1.content.content='moo' # cause fixity error
      preserved_file1.content.save
      expect_any_instance_of(Oubliette::FixityActor).to receive(:notify_fixity_error)
      job.run_job
      preserved_file1.reload
      preserved_file2.reload
      expect(preserved_file1.preservation_log.content).to be_present
      expect(preserved_file2.preservation_log.content).to be_present
      expect(preserved_file1.check_date).to be_present
      expect(preserved_file2.check_date).to be_present
    end
    
    it "aborts at max fails" do
      preserved_file1 ; preserved_file2 # create by referencing
      expect_any_instance_of(Oubliette::FixityActor).to receive(:fedora_fixity!) do false end .once
      expect_any_instance_of(Oubliette::FixityActor).to receive(:ingestion_fixity!) do false end .once
      job.max_fail_count=1
      job.run_job
      expect(job.log.last.message).to start_with("Max fail count 1 reached")
    end
  end

end