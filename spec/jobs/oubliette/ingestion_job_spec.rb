require 'rails_helper'

RSpec.describe Oubliette::IngestionJob do

  let(:content_path) { File.join(fixture_path,'test1.jpg') }

  let(:file_batch) { FactoryGirl.create(:file_batch) }
  let(:preserved_file) { FactoryGirl.create(:preserved_file, title: nil, note: nil) }
  let(:resource) { preserved_file }

  let(:request) { {resource_id: resource.id} }
  let(:channel) { Oubliette::IngestionJob.new_channel(request) }
  let(:job) { Oubliette::IngestionJob.new(channel) }    
  
  describe "::new_channel" do
    context "when ingesting in a batch" do
      let(:resource) { file_batch }

      it "prepares a file and sets add_to_parent" do
        expect(job.parent_id).to eql(file_batch.id)
        expect(job.resource_id).to be_present
        expect(job.resource_id).not_to eql(job.parent_id)
        expect(job.add_to_parent).to eql(true)
      end
    end
    context "when ingesting in a preserved file" do
      it "uses the file" do 
        expect(job.resource_id).to eql(preserved_file.id)
        expect(job.add_to_parent).not_to be_truthy
      end
    end
    context "with file content" do
      let(:file_double) { double('file', content_type: 'image/tiff', original_filename: 'test.tiff', read: 'moo') }
      let(:temp_path) { '/tmp/test/test.tiff' }
      let(:request) { {resource_id: resource.id, content: file_double} }
      it "makes a temp file" do
        expect(Oubliette::IngestionJob).to receive(:add_temp_file).with(file_double).and_return(temp_path)
        expect(job.temp_content_path).to eql(temp_path)
        expect(job.content_path).to be_nil
      end
    end
  end

  describe "#run" do
    let(:request) { {
      resource_id: resource.id, 
      title: 'test title', 
      note: 'test note',
      tag: 'testtag',
      access_groups: ['testgroup'],
      ingestion_checksum: 'md5:01234567890abcdef',
      content_path: content_path, 
      content_type: 'image/jpeg', 
      original_filename: 'test.jpg',
      ingestion_log: 'test ingestion log'
    } }
    
    before {
      expect(job).to receive(:ingestion_path).at_least(:once).and_return(content_path)
    }
    context "with valid ingestion path" do
      before {
        expect(job).to receive(:validate_ingestion_path).with(content_path).and_return(true)
      }
      it "ingests the content" do
        job.run
        preserved_file.reload

        expect(preserved_file.title).to eql('test title')
        expect(preserved_file.note).to eql('test note')
        expect(preserved_file.tag).to eql(['testtag'])
        expect(preserved_file.access_groups).to eql(['testgroup'])
        expect(preserved_file.status).to eql(Oubliette::PreservedFile::STATUS_NOT_CHECKED)
        expect(preserved_file.ingestion_checksum).to eql('md5:01234567890abcdef')
        expect(preserved_file.ingestion_date).to be_present

        expect(preserved_file.content).to be_present
        expect(preserved_file.content.mime_type).to eql('image/jpeg')
        expect(preserved_file.content.original_name).to eql('test.jpg')
        expect(preserved_file.content.content).to eql(File.open(content_path,'rb').read)
        
        expect(preserved_file.ingestion_log).to be_present
        expect(preserved_file.ingestion_log.mime_type).to eql('text/plain')
        expect(preserved_file.ingestion_log.content).to eql('test ingestion log')
      end

      context "when ingesting to parent" do
        let(:resource) { file_batch }

        it "adds to parent resource" do
          job.run
          file_batch.reload
          
          expect(job.resource.title).to be_present
          expect(job.resource.content.content).to be_present
          expect(job.resource.id).not_to eql(file_batch.id)
          expect(file_batch.files.map(&:id)).to include(job.resource.id)
        end
      end

      it "starts post_ingestion job" do
        expect {
          job.run
        }.to start_channel(Oubliette::PostIngestionJob, request: hash_including(resource_id: preserved_file.id))
        expect(job.state).to eql('post')
      end

      context "with notifications enabled" do
        let(:request) { {resource_id: resource.id, notifications: 'post_ingest'} }
        it "notifies after ingest" do
          expect(job).to receive(:send_notification).with(notification: 'post_ingest') do
            expect(Jobduct.runner_adapter.started_channels).to be_empty
            true
          end
          job.run
          expect(Jobduct.runner_adapter.started_channels).not_to be_empty        
        end
      end        
    end

    context "with invalid ingestion path" do
      before {
        expect(job).to receive(:validate_ingestion_path).with(content_path).and_return(false)
      }
      it "stops" do
        expect {
          job.run
        }.not_to start_channel(Oubliette::PostIngestionJob)
        expect(preserved_file.content.content).to be_nil
        expect(preserved_file.title).to be_nil
        expect(job.state).not_to eql('post')
      end
    end
  end

  describe "#callback" do
    it "returns ingested file after done" do
      job.state = 'post'
      job.callback(double('callback'))
      expect(job.state).to eql('done')
      expect(job.result[:preserved_file][:id]).to be_present
    end
  end

  describe "#ingestion_path" do
    let(:path) { '/tmp/test/test.tiff' }
    context "with content_path parameter" do
      let(:request) { {resource_id: preserved_file.id, content_path: path} }      
      it "returns the path" do
        expect(job.send(:ingestion_path)).to eql(path)
      end
    end
    context "with temp_content_path parameter" do
      let(:request) { {resource_id: preserved_file.id, temp_content_path: path} }      
      it "returns the path" do
        expect(job.send(:ingestion_path)).to eql(path)
      end
    end
  end

  describe "#clean" do
    it "cleans the temp file" do
      f = Tempfile.new('oubliette')
      f.write('test')
      f.close
      begin
        job.request[:temp_content_path] = f.path
        job.clean
        expect(File.exists?(f.path)).to eql(false)
      ensure
        File.unlink(f.path) if File.exists?(f.path)
      end
    end
  end
end