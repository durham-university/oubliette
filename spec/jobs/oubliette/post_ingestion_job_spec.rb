require 'rails_helper'

RSpec.describe Oubliette::PostIngestionJob do

  let(:preserved_file) { FactoryGirl.create(:preserved_file, :with_file) }

  let(:request) { {resource_id: preserved_file.id} }
  let(:channel) { Oubliette::PostIngestionJob.new_channel(request) }
  let(:job) { Oubliette::PostIngestionJob.new(channel) }    
  
  describe "#run" do
    it "starts a fixity check" do
      expect(job).to receive(:do_fixity)
      job.run
    end
  end

  describe "#do_fixity" do
    it "starts a fixity job" do
      expect {
        job.do_fixity
      }.to start_channel(Oubliette::SingleFixityJob, request: hash_including(resource_id: preserved_file.id, ))
    end
  end

  describe "#do_characterisation" do
    it "starts a characterisation job" do
      expect {
        job.do_characterisation
      }.to start_channel(Oubliette::CharacterisationJob, request: hash_including(resource_id: preserved_file.id, ))
    end
  end

  describe "#callback" do
    it "starts characterisation after fixity" do
      job.state = 'fixity'
      expect(job).to receive(:do_characterisation)
      job.callback(double('callback', success_code: Jobduct::Callback::CODE_SUCCESS, callback_params: { call: 'fixity' }))
    end
  end

end