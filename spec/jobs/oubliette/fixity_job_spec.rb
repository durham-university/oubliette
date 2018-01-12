require 'rails_helper'

RSpec.describe Oubliette::FixityJob do

  let(:preserved_file1) { FactoryGirl.create(:preserved_file, :with_file) }
  let(:preserved_file2) { FactoryGirl.create(:preserved_file, :with_file) }
  let(:preserved_file3) { FactoryGirl.create(:preserved_file, :with_file) }

  let(:request) { {fixity_mode: [:fedora, :ingestion], max_fail_count: 20, file_limit: 10, time_limit: -1 } }
  let(:channel) { Oubliette::FixityJob.new_channel(request).tap do |c| c.save end }
  let(:job) { Oubliette::FixityJob.new(channel) }  

  describe "#run" do
    it "checks preserved files" do
      preserved_file1 ; preserved_file2 # create by referencing
      expect(preserved_file1.preservation_log.content).to be_nil
      preserved_file1.content.content='moo' # cause fixity error
      preserved_file1.content.save
      expect_any_instance_of(Oubliette::FixityActor).to receive(:notify_fixity_error)
      job.run
      preserved_file1.reload
      preserved_file2.reload
      expect(preserved_file1.preservation_log.content).to be_present
      expect(preserved_file2.preservation_log.content).to be_present
      expect(preserved_file1.check_date).to be_present
      expect(preserved_file2.check_date).to be_present
    end
    
    it "sorts and limits" do
      d1 = DateTime.now - 10.seconds
      d2 = DateTime.now - 20.seconds
      preserved_file1.check_date = d1
      preserved_file1.save
      preserved_file2.check_date = d2
      preserved_file2.save
      expect(job).to receive(:file_limit).at_least(:once).and_return(1)
      job.run
      preserved_file1.reload
      preserved_file2.reload
      expect(preserved_file1.check_date).to eql(d1)
      expect(preserved_file2.check_date).to be > d2
    end
    
    it "limits by check_date" do
      d1 = DateTime.now - 10.days
      d2 = DateTime.now - 5.days
      preserved_file1.check_date = d1
      preserved_file1.save
      preserved_file2.check_date = d2
      preserved_file2.save
      preserved_file3 # create by reference, no check_date
      expect(preserved_file3.check_date).not_to be_present
      expect(job).to receive(:time_limit).at_least(:once).and_return(7)
      job.run
      preserved_file1.reload
      preserved_file2.reload
      preserved_file3.reload
      expect(preserved_file1.check_date).to be > d1
      expect(preserved_file2.check_date).to eql(d2)      
      expect(preserved_file3.check_date).to be_present
    end
    
    it "aborts at max fails" do
      request[:max_fail_count] = 1
      preserved_file1 ; preserved_file2 # create by referencing
      expect_any_instance_of(Oubliette::FixityActor).to receive(:fedora_fixity!) do false end .once
      expect_any_instance_of(Oubliette::FixityActor).to receive(:ingestion_fixity!) do false end .once
      job.run
      expect(job.log.last.message).to start_with("Max fail count 1 reached")
    end
  end

end