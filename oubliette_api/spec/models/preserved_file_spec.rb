require 'shared/model_common'

RSpec.describe Oubliette::API::PreservedFile do
  let( :all_json_s ) { %q|[{"id":"45/95/49/d8/459549d8-a5d9-4b3f-b878-f80387a7d67f","ingestion_date":"2015-11-20T14:42:24.234+00:00","status":"not checked","check_date":null,"title":"Testing","note":"Note for testing","ingestion_checksum":null},{"id":"23/50/ce/c4/2350cec4-7233-42ed-bb7e-af179a769c60","ingestion_date":"2015-11-23T10:28:22.677+00:00","status":"not checked","check_date":null,"title":"New file","note":"","ingestion_checksum":null},{"id":"28/95/a1/36/2895a136-6269-4e9d-a7a6-6c34c1026625","ingestion_date":"2015-11-23T10:48:07.334+00:00","status":"not checked","check_date":null,"title":"Jpeg test","note":"","ingestion_checksum":"md5:15eb7a5c063f0c4cdda6a7310b536ba4"},{"id":"b6/77/b0/50/b677b050-4128-4d77-ac42-8fdf55f52a69","ingestion_date":"2015-11-23T13:10:44.494+00:00","status":"not checked","check_date":null,"title":"PDF test","note":"This is a pdf file","ingestion_checksum":null}]| }
  let( :json ) { {"id" => "b6/77/b0/50/b677b050-4128-4d77-ac42-8fdf55f52a69","ingestion_date" => "2015-11-23T13:10:44.494+00:00","status" => "not checked","check_date" => "2015-11-23T13:11:00.000+00:00","title" => "PDF test","note" => "This is a pdf file","ingestion_checksum" => "md5:dcca695ddf72313d5f9f80935c58cf9ddcca695ddf72313d5f9f80935c58cf9d"} }
  let( :file ) { Oubliette::API::PreservedFile.from_json(json) }
  let( :file_fixture ) { fixture('test1.jpg') }

  it_behaves_like "model_common"

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

  describe "#as_json" do
    it "adds attributes to json" do
      json = file.as_json
      expect(json[:status]).to eql 'not checked'
      expect(json[:ingestion_checksum]).to eql 'md5:dcca695ddf72313d5f9f80935c58cf9ddcca695ddf72313d5f9f80935c58cf9d'
    end
  end

  describe "#from_json" do
    it "parses everything" do
      expect(file.status).to eql 'not checked'
      expect(file.ingestion_checksum).to eql 'md5:dcca695ddf72313d5f9f80935c58cf9ddcca695ddf72313d5f9f80935c58cf9d'
      expect(file.check_date).to eql DateTime.parse("2015-11-23T13:11:00.000+00:00")
      expect(file.ingestion_date).to eql DateTime.parse("2015-11-23T13:10:44.494+00:00")
    end
  end

  describe "::ingest" do
    let( :params ) { {title: 'ingest title', note: 'ingest note', ingestion_log: 'ingestion log', ingestion_checksum: 'md5:dcca695ddf72313d5f9f80935c58cf9ddcca695ddf72313d5f9f80935c58cf9d' } }
    let( :response ) { { status: :created, resource: json }.to_json }
    let( :response_code ) { 200 }
    let( :original_filename ) { nil }
    let( :content_type ) { nil }
    before {
      expect(Oubliette::API::PreservedFile).to receive(:post) { |url,params|
        query = params[:query]
        expect(query[:'preserved_file[content]']).to respond_to :read
        expect(query[:'preserved_file[content]'].original_filename).not_to be_nil
        expect(query[:'preserved_file[content]'].content_type).not_to be_nil
        expect(query[:'preserved_file[title]']).to eql 'ingest title'
        expect(query[:'preserved_file[note]']).to eql 'ingest note'
        expect(query[:'preserved_file[ingestion_log]']).to eql 'ingestion log'
        expect(query[:'preserved_file[ingestion_checksum]']).to eql 'md5:dcca695ddf72313d5f9f80935c58cf9ddcca695ddf72313d5f9f80935c58cf9d'
        expect(query[:'preserved_file[original_filename]']).to eql(original_filename) if original_filename
        expect(query[:'preserved_file[content_type]']).to eql(content_type) if content_type
        OpenStruct.new(body: response, code: response_code)
      }
    }
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
