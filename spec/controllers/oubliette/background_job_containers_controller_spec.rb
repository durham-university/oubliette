require 'rails_helper'

RSpec.describe Oubliette::BackgroundJobContainersController, type: :controller do

  routes { Oubliette::Engine.routes }

  context "with admin user" do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before { sign_in user }

    describe "POST #start_fixity_job" do
      it "starts the job" do
        expect(Oubliette.queue).to receive(:push).with(Oubliette::FixityJob) do |job|
          expect(job.file_limit).to be > 10
          expect(job.time_limit).to be > 2
        end
        post :start_fixity_job
      end
      it "sets params" do
        expect(Oubliette.queue).to receive(:push).with(Oubliette::FixityJob) do |job|
          expect(job.file_limit).to eql(10)
          expect(job.time_limit).to eql(2)
        end
        post :start_fixity_job, { file_limit: 10, time_limit: 2 }
      end
    end
    
    describe "POST #start_export_job" do
      it "starts the job" do
        expect(controller).to receive(:export_job_params).and_call_original
        expect(controller).to receive(:authorize_export_job_files).with(['aaa', 'bbb']).and_return(true)
        expect(Oubliette.queue).to receive(:push).with(Oubliette::ExportJob) do |job|
          expect(job.export_file_ids).to eql(['aaa', 'bbb'])
          expect(job.export_note).to eql('test note')
        end
        post :start_export_job, { export_ids: ['aaa', 'bbb'], export_note: 'test note'}
      end
      
      it "authorises the files" do
        expect(controller).to receive(:authorize_export_job_files).with(['aaa', 'bbb']).and_raise(CanCan::AccessDenied, 'not autherized')
        expect(Oubliette.queue).not_to receive(:push)
        post :start_export_job, { export_ids: ['aaa', 'bbb']}
      end
      
      it "returns json" do
        expect(controller).to receive(:authorize_export_job_files).with(['aaa', 'bbb']).and_return(true)
        expect(Oubliette.queue).to receive(:push).with(Oubliette::ExportJob)
        post :start_export_job, { export_ids: ['aaa', 'bbb'], export_note: 'test note', format: 'json'}
        json = JSON.parse(response.body)
        expect(json['status']).to eql(true)
        expect(json['job_id']).to be_present
      end
      
    end
  end
  
  context "with anonymous user" do
    describe "POST #start_fixity_job" do
      it "doesn't start the job" do
        expect(Oubliette.queue).not_to receive(:push)
        post :start_fixity_job
      end
    end
    
    describe "POST #start_export_job" do
      it "doesn't start the job" do
        expect(controller).not_to receive(:authorize_export_job_files)
        expect(Oubliette.queue).not_to receive(:push)
        post :start_export_job, { export_ids: ['aaa', 'bbb']}
      end
    end
  end
  
  context "with registered user" do
    let(:user) { FactoryGirl.create(:user) }
    before { sign_in user }
    
    describe "POST #start_fixity_job" do
      it "doesn't start the job" do
        expect(Oubliette.queue).not_to receive(:push)
        post :start_fixity_job
      end
    end
    
    describe "POST #start_export_job" do
      it "doesn't start the job" do
        expect(controller).not_to receive(:authorize_export_job_files)
        expect(Oubliette.queue).not_to receive(:push)
        post :start_export_job, { export_ids: ['aaa', 'bbb']}
      end
    end    
  end
  
  describe "#authorize_export_job_files" do
    let!(:file1) { FactoryGirl.create(:preserved_file) }
    let!(:file2) { FactoryGirl.create(:preserved_file) }
    let!(:file3) { FactoryGirl.create(:preserved_file) }
    let(:file_ids) { [file1.id, file2.id, file3.id] }
    it "authorizes each file" do
      authorized_ids = []
      expect(controller).to receive(:authorize!).at_least(:once) do |action,file|
        expect(action).to eql(:export)
        expect(file).to be_a(Oubliette::PreservedFile)
        authorized_ids << file.id
      end
      controller.send(:authorize_export_job_files, file_ids)
      expect(authorized_ids).to match_array(file_ids)
    end
  end
  
  describe "#export_job_params" do
    it "splits ids and returns params" do
      expect(controller).to receive(:params).at_least(:once).and_return({export_ids: "aaa bbb, ccc\n ddd", export_note: 'test note', export_method: 'store'})
      params = controller.send(:export_job_params)
      expect(params[:export_file_ids]).to eql(['aaa','bbb','ccc','ddd'])
      expect(params[:export_note]).to eql('test note')
      expect(params[:export_method]).to eql(:store)
    end
    
    it "limits number of ids" do
      expect(controller).to receive(:params).at_least(:once).and_return({export_ids: (1..1000).to_a.join(' ')})
      expect{ 
        controller.send(:export_job_params)
      } .to raise_error('Too many export ids given')
    end
    
    it "sanitises export_destination" do
      expect(controller).to receive(:params).at_least(:once).and_return({export_ids: 'aaa bbb', export_destination: '/tmp/test', export_method: 'store'})
      expect(controller.send(:export_job_params)[:export_destination]).not_to be_present
    end
  end
end
