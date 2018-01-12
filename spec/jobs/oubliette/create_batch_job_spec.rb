require 'rails_helper'

RSpec.describe Oubliette::CreateBatchJob do

  let(:request) { {title: 'test title', note: 'test note'} }
  let(:channel) { Oubliette::CreateBatchJob.new_channel(request) }
  let(:job) { Oubliette::CreateBatchJob.new(channel) }    
  
  describe "#run" do
    it "creates the batch" do
      job.run
      batch_id = job.result[:batch][:id]
      expect(batch_id).to be_present
      batch = Oubliette::FileBatch.find(batch_id)
      expect(batch.title).to eql('test title')
      expect(batch.note).to eql('test note')
    end
  end

end