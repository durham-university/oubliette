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

    it "validates checksum" do
      expect(preserved_file).to be_valid
      preserved_file.ingestion_checksum='md5:15eb7a5c063f0c4cdda6a7310b536ba3'
      expect(preserved_file).not_to be_valid
      preserved_file.ingestion_checksum=nil
      expect(preserved_file).to be_valid
      preserved_file.ingestion_checksum='dummy:15eb7a5c063f0c4cdda6a7310b536ba4'
      expect(preserved_file).not_to be_valid
      preserved_file.ingestion_checksum='sha256:cbf3aedbc2ba1de4842bc9565c8e180cd8e5e2c38cc1c2b93ae21b6d121c50a9'
      expect(preserved_file).to be_valid
      preserved_file.content.content = ''
      expect(preserved_file).not_to be_valid
    end
  end
end
