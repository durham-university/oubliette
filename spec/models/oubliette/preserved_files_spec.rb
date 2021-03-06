require 'rails_helper'

RSpec.describe Oubliette::PreservedFile do

  let(:preserved_file) { FactoryGirl.create(:preserved_file, :with_file, :with_preservation_log, title: 'test title', note: 'test note') }

  describe "persisting" do
    it "saves and loads from Fedora" do
      preserved_file.reload
      expect(preserved_file.title).to eql 'test title'
      expect(preserved_file.note).to eql 'test note'
      expect(preserved_file.status).to eql Oubliette::PreservedFile::STATUS_NOT_CHECKED
      expect(preserved_file.content.content).to be_present
      expect(preserved_file.content.size).to be > 1000
      expect(preserved_file.content.mime_type).to eql 'image/jpeg'
      expect(preserved_file.ingestion_log.content).to eql 'Ingested through factory girl'
      expect(preserved_file.preservation_log.content).to eql 'Preservation log contents'
    end

    it "can be updated" do
      preserved_file.title = 'changed title'
      preserved_file.preservation_log.content += "\nAnother log entry"
      preserved_file.status = Oubliette::PreservedFile::STATUS_PASS
      preserved_file.save
      preserved_file.reload
      expect(preserved_file.title).to eql 'changed title'
      expect(preserved_file.status).to eql Oubliette::PreservedFile::STATUS_PASS
      expect(preserved_file.preservation_log.content).to eql "Preservation log contents\nAnother log entry"
    end
  end
  
  describe "tags" do
    let(:preserved_file) { FactoryGirl.create(:preserved_file, title: 'test1', tag: ['test','othertag']) }
    let(:preserved_file2) { FactoryGirl.create(:preserved_file, title: 'test2', tag: ['test']) }
    let(:preserved_file3) { FactoryGirl.create(:preserved_file, title: 'test3', tag: []) }
    it "saves them" do
      preserved_file.reload
      expect(preserved_file.tag).to match_array(['test','othertag'])
    end
    it "can search with them" do
      preserved_file ; preserved_file2 ; preserved_file3 # create by referencing
      expect(Oubliette::PreservedFile.where(tag: 'test').map(&:id)).to match_array([preserved_file.id, preserved_file2.id])
      expect(Oubliette::PreservedFile.where(tag: 'othertag').map(&:id)).to match_array([preserved_file.id])
      expect(Oubliette::PreservedFile.where(tag: 'thirdtag').map(&:id)).to match_array([])
    end
  end

  describe "log setters" do
    it "can set ingestion log with a string" do
      preserved_file.ingestion_log = 'new log contents'
      preserved_file.save
      preserved_file.reload
      expect(preserved_file.ingestion_log.content).to eql 'new log contents'
    end
    it "can set preservation log with a string" do
      preserved_file.preservation_log = 'new log contents'
      preserved_file.save
      preserved_file.reload
      expect(preserved_file.preservation_log.content).to eql 'new log contents'
    end
    it "can set logs from constructor" do
      f = Oubliette::PreservedFile.create(title: 'test title', ingestion_log: 'ingestion log contents', preservation_log: 'preservation log contents')
      expect(f.ingestion_log.content).to eql 'ingestion log contents'
      expect(f.preservation_log.content).to eql 'preservation log contents'
    end
  end

  describe "validation" do
    it "validates status" do
      preserved_file.status = Oubliette::PreservedFile::STATUS_NOT_CHECKED
      expect(preserved_file).to be_valid
      preserved_file.status = Oubliette::PreservedFile::STATUS_PASS
      expect(preserved_file).to be_valid
      preserved_file.status = Oubliette::PreservedFile::STATUS_ERROR
      expect(preserved_file).to be_valid
      preserved_file.status = 'something else'
      expect(preserved_file).not_to be_valid
      preserved_file.status = nil
      expect(preserved_file).not_to be_valid
    end
  end
  
  describe "#check_ingestion_fixity" do
    it "validates checksum" do
      expect(preserved_file.check_ingestion_fixity).to eql(true)
      preserved_file.ingestion_checksum='md5:15eb7a5c063f0c4cdda6a7310b536ba3'
      expect(preserved_file.check_ingestion_fixity).not_to eql(true)
      preserved_file.ingestion_checksum=nil
      expect(preserved_file.check_ingestion_fixity).to eql(true)
      preserved_file.ingestion_checksum='dummy:15eb7a5c063f0c4cdda6a7310b536ba4'
      expect(preserved_file.check_ingestion_fixity).not_to eql(true)
      preserved_file.ingestion_checksum='sha256:cbf3aedbc2ba1de4842bc9565c8e180cd8e5e2c38cc1c2b93ae21b6d121c50a9'
      expect(preserved_file.check_ingestion_fixity).to eql(true)
      preserved_file.content.content = 'test'
      preserved_file.save
      preserved_file.reload
      expect(preserved_file.check_ingestion_fixity).not_to eql(true)
    end
  end

  describe "::ingest_file" do
    let( :preserved_file ) { Oubliette::PreservedFile.ingest_file('ingested contents', title: 'file title', ingestion_log: 'ingestion log contents') }
    it "sets file contents" do
      expect(preserved_file.content.content).to eql 'ingested contents'
    end
    it "sets ingestion date" do
      expect(preserved_file.ingestion_date.to_i).to be_within(60).of(DateTime.now.to_i)
    end
    it "sets other attributes" do
      expect(preserved_file.title).to eql 'file title'
      expect(preserved_file.ingestion_log.content).to eql 'ingestion log contents'
    end
    it "is valid" do
      expect(preserved_file).to be_valid
    end
  end
end
