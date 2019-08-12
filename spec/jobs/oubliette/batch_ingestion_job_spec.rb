require 'rails_helper'

RSpec.describe Oubliette::BatchIngestionJob do

  let(:content_path) { File.join(fixture_path,'test1.jpg') }

  let(:file_batch) { FactoryGirl.create(:file_batch) }
  let(:resource) { file_batch }

  let(:files){ [ 
    {file: '/tmp/test1.tiff', original_filename: 'test1.tiff', title: '1'}, 
    {file: '/tmp/test2.tiff', original_filename: 'test2.tiff', title: '2'},
    {file: '/tmp/test3.tiff', original_filename: 'test3.tiff', title: '3'}
  ] }
  let(:request) { {
    resource_id: resource.id, 
    files: files, 
    notifications: 'post_ingest',
    job_tag: 'testtag',
    user: user.user_key
  } }
  let(:channel) { Oubliette::BatchIngestionJob.new_channel(request) }
  let(:job) { Oubliette::BatchIngestionJob.new(channel) }    
  let(:user) { FactoryGirl.create(:user, :admin) }

  describe ":create_batch" do
    let(:batch) { Oubliette::BatchIngestionJob.create_batch(batch_params)}
    let(:batch_params) { { batch_title: 'test title', batch_note: 'test note', user: user.user_key } }
    it "creates a file batch" do
      expect(batch).to be_a(Oubliette::FileBatch)
      expect(batch.title).to eql('test title')
      expect(batch.note).to eql('test note')
    end

    context "with editor user" do
      let(:user) { FactoryGirl.create(:user, roles: ['editor', 'testgroup'], default_access_group: 'testgroup') }
      it "it sets default access groups" do
        expect(batch).to be_a(Oubliette::FileBatch)
        expect(batch.access_groups).to eql(['testgroup'])
      end
      it "doesn't create batch with invalid access_groups" do
        batch_params[:access_groups] = 'invalidgroup'
        expect {
          batch
        } .to raise_error("Invalid batch attributes. Access groups current user cannot set these access groups")
      end
    end
  end

  describe "#files_updated" do
    it "starts the next if none going in oubliette" do
      job.ingested_files = [{file: 'test1.tiff', status: 'finished'}, {file: 'test2.tiff', status: 'pending'}]
      expect(job).to receive(:ingest_next_file)
      expect(job).not_to receive(:send_notification)
      job.send(:files_updated)
    end

# Post ingestion handling disabled with reduced concurrency
#    it "detects when all post_ingest" do
#      job.ingested_files = [{file: 'test1.tiff', status: 'finished'}, {file: 'test2.tiff', status: 'post_ingest'}]
#      expect(job).not_to receive(:ingest_next_file)
#      expect(job).to receive(:send_notification).with(notification: 'post_ingest')
#      job.send(:files_updated)
#    end

    it "detects when job done" do
      expect(job.oubliette_files).to be_nil
      job.ingested_files = [{file: 'test1.tiff', status: 'finished'}, {file: 'test2.tiff', status: 'finished'}]
      expect(job).not_to receive(:ingest_next_file)
      expect(job).not_to receive(:send_notification)
      job.send(:files_updated)
      expect(job.oubliette_files).to be_present
      expect(job.oubliette_batch).to be_present
    end

    it "does nothing when nothing needs doing" do
      job.ingested_files = [{file: 'test1.tiff', status: 'sent'}, {file: 'test2.tiff', status: 'pending'}]
      expect(job).not_to receive(:ingest_next_file)
      expect(job).not_to receive(:send_notification)
      job.send(:files_updated)
      expect(job.oubliette_files).to be_nil
    end
  end

  describe "#ingest_next_file" do
    it "starts next ingestion" do
      job.ingested_files = files.map do |f| f.merge(status: 'pending') end
      job.ingested_files[0][:status] = 'finished'
      expect {
        job.send(:ingest_next_file)
      }.to start_channel(Oubliette::IngestionJob, request: hash_including(
        title: '2',
        content_path: '/tmp/test2.tiff',
        parent_id: resource.id,
        job_tag: 'testtag/file//tmp/test2.tiff'
      ))
      expect(job.ingested_files[1][:status]).to eql('sent')
    end
  end

  describe "#run" do
    it "sets up ingested_files and starts the process" do
      expect(job).to receive(:files_updated) do
        expect(job.ingested_files).to match([
          {file: '/tmp/test1.tiff', title: '1', original_filename: 'test1.tiff', status: 'pending'}, 
          {file: '/tmp/test2.tiff', title: '2', original_filename: 'test2.tiff', status: 'pending'},
          {file: '/tmp/test3.tiff', title: '3', original_filename: 'test3.tiff', status: 'pending'}
        ])
      end
      job.run
    end
  end

  describe "everything" do
    it "processes all files" do
      expect(job).to receive(:local_call).with(kind_of(String),hash_including(content_path: '/tmp/test1.tiff')).ordered do
        job.callback(OpenStruct.new(callback_params: {original_file: '/tmp/test1.tiff'}, success_code: Jobduct::Callback::CODE_SUCCESS, result: {preserved_file: {id: 'pf1id'}}))
#        job.notify(OpenStruct.new(payload: {notification: 'post_ingest'}, callback_params: {original_file: '/tmp/test1.tiff'}, result: { preserved_file: { id: 'pf1id'}}))
      end
      expect(job).to receive(:local_call).with(kind_of(String),hash_including(content_path: '/tmp/test2.tiff')).ordered do
        job.callback(OpenStruct.new(callback_params: {original_file: '/tmp/test2.tiff'}, success_code: Jobduct::Callback::CODE_SUCCESS, result: {preserved_file: {id: 'pf2id'}}))
#        job.callback(OpenStruct.new(callback_params: {original_file: '/tmp/test1.tiff'}, success_code: Jobduct::Callback::CODE_SUCCESS, result: {preserved_file: {id: 'pf1id'}}))
#        job.notify(OpenStruct.new(payload: {notification: 'post_ingest'}, callback_params: {original_file: '/tmp/test2.tiff'}, result: {preserved_file: {id: 'pf2id'}}))
      end
      expect(job).to receive(:local_call).with(kind_of(String),hash_including(content_path: '/tmp/test3.tiff')).ordered do
        job.callback(OpenStruct.new(callback_params: {original_file: '/tmp/test3.tiff'}, success_code: Jobduct::Callback::CODE_SUCCESS, result: {preserved_file: {id: 'pf3id'}}))
#        job.notify(OpenStruct.new(payload: {notification: 'post_ingest'}, callback_params: {original_file: '/tmp/test3.tiff'}, result: {preserved_file: {id: 'pf3id'}}))
#        job.callback(OpenStruct.new(callback_params: {original_file: '/tmp/test2.tiff'}, success_code: Jobduct::Callback::CODE_SUCCESS, result: {preserved_file: {id: 'pf2id'}}))
#        job.callback(OpenStruct.new(callback_params: {original_file: '/tmp/test3.tiff'}, success_code: Jobduct::Callback::CODE_SUCCESS, result: {preserved_file: {id: 'pf3id'}}))

        job.ingested_files.each do |file|
          expect(file[:status]).to eql('finished')
          expect(file[:oubliette_id]).to be_present
        end
        expect(job.oubliette_files).to match([
          {file: '/tmp/test1.tiff', oubliette_id: 'pf1id'},
          {file: '/tmp/test2.tiff', oubliette_id: 'pf2id'},
          {file: '/tmp/test3.tiff', oubliette_id: 'pf3id'}
        ])
      end
      job.run
    end
  end

end
