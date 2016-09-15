require 'rails_helper'

RSpec.describe Oubliette::FileBatch do

  let(:file_batch) { FactoryGirl.create(:file_batch, :with_files, title: 'test title', note: 'test note') }
  let(:preserved_file) { FactoryGirl.create(:preserved_file) }

  describe "persisting" do
    it "saves and loads from Fedora" do
      file_batch.reload
      expect(file_batch.title).to eql 'test title'
      expect(file_batch.note).to eql 'test note'
      expect(file_batch.files.to_a.count).to eql(2)
    end

    it "can be updated" do
      file_batch.title = 'changed title'
      file_batch.ordered_members << preserved_file
      preserved_file.save
      preserved_file.reload
      expect(file_batch.title).to eql 'changed title'
      expect(file_batch.files.to_a.count).to eql(3)
    end
  end
  
  describe "#allow_destroy?" do
    let(:empty_batch) { FactoryGirl.create(:file_batch) }
    it "can't be destroyed if not empty" do
      expect(file_batch.allow_destroy?).to eql(false)
    end
    it "can be destroyed when empty" do
      expect(empty_batch.allow_destroy?).to eql(true)
    end
  end
  
  describe "#as_json" do
    let(:json) {file_batch.as_json}
    let(:json_with_children) {file_batch.as_json(include_children: true)}
    it "adds necessary properties in json" do
      expect(json['title']).to eql('test title')
      expect(json['type']).to eql('batch')
      expect(json_with_children['files'].count).to eql(2)
    end
  end
  
  describe ":all_top" do
    let(:all_top) { Oubliette::FileBatch.all_top }
    let(:all_top_ids) { all_top.map(&:id) }
    it "returns batches and top level files" do
      file_batch ; preserved_file # create by referencing
      expect(all_top_ids).to match_array([file_batch.id, preserved_file.id])
    end
  end
  
end
