require 'shared/model_common'

RSpec.describe Oubliette::API::PreservedFile do
  let( :all_json_s ) { %q|{"resources":[{"id":"45/95/49/d8/459549d8-a5d9-4b3f-b878-f80387a7d67f","ingestion_date":"2015-11-20T14:42:24.234+00:00","status":"not checked","check_date":null,"title":"Testing","note":"Note for testing","tag":["test","other"],"ingestion_checksum":null,"parent_id":"parentid123"},{"id":"23/50/ce/c4/2350cec4-7233-42ed-bb7e-af179a769c60","ingestion_date":"2015-11-23T10:28:22.677+00:00","status":"not checked","check_date":null,"title":"New file","note":"","tag":[],"ingestion_checksum":null},{"id":"28/95/a1/36/2895a136-6269-4e9d-a7a6-6c34c1026625","ingestion_date":"2015-11-23T10:48:07.334+00:00","status":"not checked","check_date":null,"title":"Jpeg test","note":"","tag":[],"ingestion_checksum":"md5:15eb7a5c063f0c4cdda6a7310b536ba4"},{"id":"b6/77/b0/50/b677b050-4128-4d77-ac42-8fdf55f52a69","ingestion_date":"2015-11-23T13:10:44.494+00:00","status":"not checked","check_date":null,"title":"PDF test","note":"This is a pdf file","tag":["test","other"],"ingestion_checksum":null}]}| }
  let( :json ) { {"id" => "b6/77/b0/50/b677b050-4128-4d77-ac42-8fdf55f52a69","ingestion_date" => "2015-11-23T13:10:44.494+00:00","status" => "not checked","check_date" => "2015-11-23T13:11:00.000+00:00","title" => "PDF test","note" => "This is a pdf file", "tag" => ["test","other"],"ingestion_checksum" => "md5:dcca695ddf72313d5f9f80935c58cf9ddcca695ddf72313d5f9f80935c58cf9d", "job_tag" => "test_job", "parent_id" => "parentid123"} }
  let( :file ) { Oubliette::API::PreservedFile.from_json(json) }
  let( :file_fixture ) { fixture('test1.jpg') }

  it_behaves_like "model_common"
  
  before {
    # reset memoised variable so that both settings can be tested
    Oubliette::API::PreservedFile.instance_variable_set(:@path_ingest, nil)
  }

  describe "all" do
    it "parses the response" do
      expect(Oubliette::API::PreservedFile).to receive(:get).and_return(OpenStruct.new(body: all_json_s, code: 200))
      resp = Oubliette::API::PreservedFile.all
      expect(resp).to be_a Array
      expect(resp.size).to eql 4
      resp.each do |repo|
        expect(repo).to be_a Oubliette::API::PreservedFile
      end
    end
  end
  
  describe "#record_url" do
    let(:base_url) {'http://www.example.com/oubliette'}
    before{
      allow(Oubliette::API::PreservedFile).to receive(:base_uri).and_return(base_url)
    }
    it "returns the url" do
      expect(file.record_url).to eql('http://www.example.com/oubliette/preserved_files/b6%2F77%2Fb0%2F50%2Fb677b050-4128-4d77-ac42-8fdf55f52a69')
    end
  end
  
  describe ":record_url" do
    let(:base_url) {'http://www.example.com/oubliette'}
    before{
      allow(Oubliette::API::PreservedFile).to receive(:base_uri).and_return(base_url)
    }
    it "returns the url" do
      expect(Oubliette::API::PreservedFile.record_url('testid')).to eql('http://www.example.com/oubliette/preserved_files/testid')
    end    
  end

  describe "#as_json" do
    it "adds attributes to json" do
      json = file.as_json
      expect(json['status']).to eql 'not checked'
      expect(json['tag']).to eql(['test','other'])
      expect(json['ingestion_checksum']).to eql 'md5:dcca695ddf72313d5f9f80935c58cf9ddcca695ddf72313d5f9f80935c58cf9d'
      expect(json['job_tag']).to eql 'test_job'
      expect(json['parent_id']).to eql 'parentid123'
    end
  end

  describe "#from_json" do
    it "parses everything" do
      expect(file.status).to eql 'not checked'
      expect(file.tag).to eql(['test','other'])
      expect(file.ingestion_checksum).to eql 'md5:dcca695ddf72313d5f9f80935c58cf9ddcca695ddf72313d5f9f80935c58cf9d'
      expect(file.check_date).to eql DateTime.parse("2015-11-23T13:11:00.000+00:00")
      expect(file.ingestion_date).to eql DateTime.parse("2015-11-23T13:10:44.494+00:00")
      expect(file.job_tag).to eql 'test_job'
      expect(file.parent_id).to eql 'parentid123'
    end
  end

  describe "#parent" do
    let(:batch) { double('batch') }
    it "finds the batch" do
      expect(Oubliette::API::FileBatch).to receive(:find).with('parentid123').and_return(batch)
      expect(file.parent).to eql(batch)
    end
  end
  
  describe "#download" do
    let(:mock_http){ double('mock_http') }
    it "downloads from oubliette" do
      expect(file).to receive(:download_url).and_return('http://example.com/foo')
      expect(Oubliette::API::PreservedFile).to receive(:authentication_config).at_least(:once).and_return({ 'username' => 'moo', 'password' => 'baa'})
      expect(Net::HTTP).to receive(:start) do |*args,&block|
        expect(args.first).to eql('example.com')
        expect(mock_http).to receive(:request) do |*args,&block|
          expect(args.first['authorization']).to eql(args.first.send(:basic_encode,'moo','baa'))
          block.call('content')
          block.call('morecontent')
        end
        block.call(mock_http)
      end
      output = StringIO.new
      file.download do |content|
        output << content
      end
      expect(output.string).to eql('contentmorecontent')
    end
  end
  
  describe "::export" do
    it "posts the request" do
      expect(Oubliette::API::PreservedFile).to receive(:post) do |url, params|
        expect(url).to eql("/background_job_containers/start_export_job.json")
        query = params[:query]
        expect(query[:export_ids]).to eql(['aaa', 'bbb'])
        expect(query[:export_method]).to eql(:store)
        expect(query[:export_destination]).to eql('/tmp/test')
        expect(query[:export_note]).to eql('test note')
        
        OpenStruct.new(body: '{"status":true, "job_id":"testjobid"}', code: 200)
      end
      expect(Oubliette::API::PreservedFile).to receive(:local_mode?).and_return(false)
      expect(Oubliette::API::PreservedFile.export(export_ids: ['aaa', 'bbb'], export_method: :store, export_destination: '/tmp/test', export_note: 'test note')).to eql('testjobid')
    end
  end

  describe "::ingest" do
    let( :params ) { {title: 'ingest title', note: 'ingest note', tag: ['test'], ingestion_log: 'ingestion log', ingestion_checksum: 'md5:dcca695ddf72313d5f9f80935c58cf9ddcca695ddf72313d5f9f80935c58cf9d' } }
    let( :response ) { { status: :created, resource: json }.to_json }
    let( :response_code ) { 200 }
    let( :original_filename ) { nil }
    let( :content_type ) { nil }
    let( :job_tag ) { nil }
    before {
      expect(Oubliette::API::PreservedFile).to receive(:post) { |url,params|
        query = params[:query]
        query_content_check.call(query)
        expect(query[:'preserved_file[title]']).to eql 'ingest title'
        expect(query[:'preserved_file[note]']).to eql 'ingest note'
        expect(query[:'preserved_file[tag]']).to eql(['test'])
        expect(query[:'preserved_file[ingestion_log]']).to eql 'ingestion log'
        expect(query[:'preserved_file[ingestion_checksum]']).to eql 'md5:dcca695ddf72313d5f9f80935c58cf9ddcca695ddf72313d5f9f80935c58cf9d'
        expect(query[:'preserved_file[original_filename]']).to eql(original_filename) if original_filename
        expect(query[:'preserved_file[content_type]']).to eql(content_type) if content_type
        expect(query[:'preserved_file[job_tag]']).to eql(job_tag) if job_tag
        OpenStruct.new(body: response, code: response_code)
      }
    }
    let(:query_content_check) { 
      Proc.new do |query|
        expect(query[:'preserved_file[content]']).to respond_to :read
        expect(query[:'preserved_file[content]'].original_filename).not_to be_nil
        expect(query[:'preserved_file[content]'].content_type).not_to be_nil
      end
    }
    describe "when sending file path" do
      let(:query_content_check) { 
        Proc.new do |query|
          expect(query[:'preserved_file[content_path]']).to eql(file_fixture.path)
        end
      }
      it "ingests files" do
        allow(Oubliette::API).to receive(:config).and_return({'path_ingest' => true})
        Oubliette::API::PreservedFile.ingest(file_fixture, params)
      end
    end
    it "ingests files" do
      Oubliette::API::PreservedFile.ingest(file_fixture, params)
    end
    it "ingests strings" do
      Oubliette::API::PreservedFile.ingest('file contents', params)
    end
    context "with original filename" do
      let( :original_filename ) { 'test1.jpg' }
      it "sets original file name" do
        params[:original_filename] = original_filename
        Oubliette::API::PreservedFile.ingest(file_fixture, params)
      end
    end
    context "with content type" do
      let( :content_type ) { 'image/jpeg' }
      it "sets content_type" do
        params[:content_type] = content_type
        Oubliette::API::PreservedFile.ingest(file_fixture, params)
      end
    end
    context "with job_tag" do
      let( :job_tag ) { 'test_job' }
      it "sets job_tag" do
        params[:job_tag] = job_tag
        Oubliette::API::PreservedFile.ingest(file_fixture, params)
      end
    end
    context "with error" do
      let( :response ) { { status: :error }.to_json }
      it "handles errors" do
        expect {
          Oubliette::API::PreservedFile.ingest(file_fixture, params)
        }.to raise_error(Oubliette::API::IngestError)
      end
    end
    context "with error code" do
      let( :response ) { { status: :error }.to_json }
      let( :resporse_code ) { 404 }
      it "handles errors" do
        expect {
          Oubliette::API::PreservedFile.ingest(file_fixture, params)
        }.to raise_error(Oubliette::API::IngestError)
      end
    end
  end
end
