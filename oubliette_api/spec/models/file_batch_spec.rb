require 'shared/model_common'

RSpec.describe Oubliette::API::FileBatch do
  let( :all_json_s ) { %q|{"resources":[{"id":"45/95/49/d8/459549d8-a5d9-4b3f-b878-f80387a7d67f","ingestion_date":"2015-11-20T14:42:24.234+00:00","title":"Testing","note":"Note for testing","type":"batch"},{"id":"23/50/ce/c4/2350cec4-7233-42ed-bb7e-af179a769c60","ingestion_date":"2015-11-23T10:28:22.677+00:00","title":"New file","note":"","type":"batch"},{"id":"28/95/a1/36/2895a136-6269-4e9d-a7a6-6c34c1026625","ingestion_date":"2015-11-23T10:48:07.334+00:00","title":"Jpeg test","note":"","type":"batch"},{"id":"b6/77/b0/50/b677b050-4128-4d77-ac42-8fdf55f52a69","ingestion_date":"2015-11-23T13:10:44.494+00:00","title":"PDF test","note":"This is a pdf file"}]}| }
  let( :json ) { {"id" => "b6/77/b0/50/b677b050-4128-4d77-ac42-8fdf55f52a69","ingestion_date" => "2015-11-23T13:10:44.494+00:00","title" => "PDF test","note" => "This is a pdf file", "type" => "batch"} }
  let( :file_json_s ) { %q|{"id":"45/95/49/d8/459549d8-a5d9-4b3f-b878-f80387a7d67f","ingestion_date":"2015-11-20T14:42:24.234+00:00","status":"not checked","check_date":null,"title":"Test file","note":"Note for testing","ingestion_checksum":null}| }
  let( :file_batch ) { Oubliette::API::FileBatch.from_json(json) }

  it_behaves_like "model_common"

  describe "all" do
    it "parses the response" do
      expect(Oubliette::API::FileBatch).to receive(:get).and_return(OpenStruct.new(body: all_json_s, code: 200))
      resp = Oubliette::API::FileBatch.all
      expect(resp).to be_a Array
      expect(resp.size).to eql 4
      batch_count = 0
      file_count = 0
      resp.each do |r|
        batch_count += 1 if r.is_a?(Oubliette::API::FileBatch)
        file_count += 1 if r.is_a?(Oubliette::API::PreservedFile)
      end
      expect(batch_count).to eql(3)
      expect(file_count).to eql(1)
    end
  end
  
  describe "#record_url" do
    let(:base_url) {'http://www.example.com/oubliette'}
    before{
      allow(Oubliette::API::FileBatch).to receive(:base_uri).and_return(base_url)
    }
    it "returns the url" do
      expect(file_batch.record_url).to eql('http://www.example.com/oubliette/file_batches/b6%2F77%2Fb0%2F50%2Fb677b050-4128-4d77-ac42-8fdf55f52a69')
    end
  end
  
  describe ":record_url" do
    let(:base_url) {'http://www.example.com/oubliette'}
    before{
      allow(Oubliette::API::FileBatch).to receive(:base_uri).and_return(base_url)
    }
    it "returns the url" do
      expect(Oubliette::API::FileBatch.record_url('testid')).to eql('http://www.example.com/oubliette/file_batches/testid')
    end    
  end
  
  describe "#files" do
    context "with a fully feched resource" do
      let(:file_batch) { Oubliette::API::FileBatch.from_json(json.merge('files' => [JSON.parse(file_json_s)])) }
      it "returns files without fetching again" do
        expect(file_batch).not_to receive(:fetch)
        expect(file_batch.files.count).to eql(1)
        expect(file_batch.files.first).to be_a(Oubliette::API::PreservedFile)
        expect(file_batch.files.first.title).to eql('Test file')
      end
    end
    context "with a stub resource" do
      it "fetches and returns sub_collections" do
        expect(file_batch).to receive(:local_mode?).and_return(false)
        expect(Oubliette::API::FileBatch).to receive(:get).and_return(OpenStruct.new(body: json.merge('files' => [JSON.parse(file_json_s)]).to_json, code: 200))
        expect(file_batch.files.count).to eql(1)
        expect(file_batch.files.first).to be_a(Oubliette::API::PreservedFile)
        expect(file_batch.files.first.title).to eql('Test file')
      end
    end
  end
  
  describe ":create" do
    let(:params) { { title: 'new batch', note: 'test note', dummy: 'dummy'} }
    it "posts the resource" do
      expect(Oubliette::API::FileBatch).to receive(:post).with('/file_batches.json', {body: { file_batch: {title: 'new batch', note: 'test note'}}}) \
        .and_return(OpenStruct.new(code: 200, body: '{"resource":{"id":"123456","title":"new batch","note":"test note","type":"batch"}}'))
      res = Oubliette::API::FileBatch.create(params)
      expect(res).to be_a(Oubliette::API::FileBatch)
      expect(res.id).to eql('123456')
      expect(res.title).to eql('new batch')
      expect(res.note).to eql('test note')
    end
    
    it "passes on no_duplicates" do
      params[:no_duplicates]='true'
      expect(Oubliette::API::FileBatch).to receive(:post).with('/file_batches.json', {body: { file_batch: {title: 'new batch', note: 'test note'}, no_duplicates: 'true'}}) \
        .and_return(OpenStruct.new(code: 200, body: '{"resource":{"id":"123456","title":"new batch","note":"test note","type":"batch"}}'))
      res = Oubliette::API::FileBatch.create(params)
      expect(res).to be_a(Oubliette::API::FileBatch)
      expect(res.id).to eql('123456')
    end
  end
  
  describe ":create_local" do
    before { 
      expect(Oubliette::API::FileBatch).to receive(:local_mode?).and_return(true)
      expect(Oubliette::API::FileBatch).to receive(:create_local).and_call_original
      expect(Oubliette::API::FileBatch).not_to receive(:post)
    }
    let(:params) { { title: 'new batch', note: 'test note', dummy: 'dummy'} }
    let(:local_class_double) { double('local class') }
    it "creates the resource" do
      expect(Oubliette::API::FileBatch).to receive(:local_class).and_return(local_class_double)
      expect(local_class_double).to receive(:create) do |params|
        double('instance').tap do |inst|
          expect(inst).to receive(:as_json).and_return(params.stringify_keys.merge({'id'=>'123456','type'=>'batch'}))
        end
      end
      res = Oubliette::API::FileBatch.create(params)
      expect(res).to be_a(Oubliette::API::FileBatch)
      expect(res.id).to eql('123456')
      expect(res.title).to eql('new batch')
      expect(res.note).to eql('test note')      
      expect(res.ingestion_date).to be_present
    end
  end

  describe "#as_json" do
    it "adds attributes to json" do
      json = file_batch.as_json
      expect(json['note']).to eql "This is a pdf file"
    end
  end

  describe "#from_json" do
    it "parses everything" do
      expect(file_batch.note).to eql "This is a pdf file"
      expect(file_batch.ingestion_date).to eql DateTime.parse("2015-11-23T13:10:44.494+00:00")
    end
  end
end
