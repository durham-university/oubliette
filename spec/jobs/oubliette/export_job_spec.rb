require 'rails_helper'

RSpec.describe Oubliette::ExportJob do

  let(:preserved_file1) { FactoryGirl.create(:preserved_file, :with_file) }
  let(:preserved_file2) { FactoryGirl.create(:preserved_file, :with_file) }
  let(:preserved_file3) { FactoryGirl.create(:preserved_file, :with_file) }

  let(:request) { {export_file_ids: ['aaa','bbb'], export_method: :test_method, export_destination: '/tmp/test', export_note: 'Export Note'} }
  let(:channel) { Oubliette::ExportJob.new_channel(request) }
  let(:job) { Oubliette::ExportJob.new(channel) }    
  let!(:actor) { Oubliette::ExportActor.new(nil, request) }

  describe "::new_channel" do
    context "with packed ids" do
      let(:request) { {export_file_ids: "aaa\nbbb", export_method: :test_method, export_destination: '/tmp/test', export_note: 'Export Note'} }
      it "parses ids" do
        expect(job.export_file_ids).to eql(['aaa','bbb'])
      end
    end
  end
  
  describe "#run" do
    before {
      expect(Oubliette::ExportActor).to receive(:new) do |resource,options|
        expect(resource).to be_nil
        expect(options).to eql(request)
        actor
      end      
    }        
    it "runs the actor" do
      expect(actor).to receive(:export!)
      job.run
    end
  end

end