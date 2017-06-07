require 'rails_helper'

RSpec.describe Oubliette::ExportJob do

  let(:preserved_file1) { FactoryGirl.create(:preserved_file, :with_file) }
  let(:preserved_file2) { FactoryGirl.create(:preserved_file, :with_file) }
  let(:preserved_file3) { FactoryGirl.create(:preserved_file, :with_file) }

  let(:job_params) { {export_file_ids: ['aaa','bbb'], export_method: :test_method, export_destination: '/tmp/test', export_note: 'Export Note'} }
  let(:job) { Oubliette::ExportJob.new(job_params) }

  describe "marshalling" do
    let(:serial) { Marshal.dump(job) }
    let(:deserial) { Marshal.load(serial) }
    it "preserves variables" do
      expect(deserial.export_file_ids).to eql(['aaa','bbb'])
      expect(deserial.export_method).to eql(:test_method)
      expect(deserial.export_destination).to eql('/tmp/test')
      expect(deserial.export_note).to eql('Export Note')
      expect(deserial.resource_id).to be_present
    end
  end

  describe "#run_job" do
    it "runs the actor" do
      expect_any_instance_of(Oubliette::ExportActor).to receive(:export!) do |actor|
        expect(actor.export_file_ids).to eql(['aaa','bbb'])
        expect(actor.export_method).to eql(:test_method)
        expect(actor.export_destination).to eql('/tmp/test')
        expect(actor.export_note).to eql('Export Note')
        expect(actor.log).to eq(job.log)
      end
      job.run_job
    end
  end

end