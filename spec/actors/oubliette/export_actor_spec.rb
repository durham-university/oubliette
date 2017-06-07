require 'rails_helper'

RSpec.describe Oubliette::ExportActor do
  let(:file1) { FactoryGirl.create(:preserved_file) }
  let(:file2) { FactoryGirl.create(:preserved_file) }
  let(:file3) { FactoryGirl.create(:preserved_file) }
  let(:file4) { FactoryGirl.create(:preserved_file) }
  
  let(:user) { nil }
  let(:files) { [] }
  let(:export_note) { "Test export" }
  let(:actor_attributes) { {export_file_ids: files.map(&:id), export_note: export_note} }
  
  let(:actor) { Oubliette::ExportActor.new(user, actor_attributes) }
  
  describe "#export!" do
    it "calls all methods" do
      expect(actor).to receive(:zip_files).and_return(true)
      expect(actor).to receive(:send_zip).and_return(true)
      expect(actor).to receive(:finish_export).and_return(true)
      actor.export!
    end
    it "aborts when something fails" do
      expect(actor).to receive(:zip_files).and_return(false)
      expect(actor).not_to receive(:send_zip)
      expect(actor).to receive(:finish_export).and_return(true)
      actor.export!
    end
  end
  
  describe "#export_temp_dir" do
    it "uses Oubliette.config" do
      expect(Oubliette).to receive(:config).and_return({'export_temp_dir' => '/test/temp'})
      expect(actor.export_temp_dir).to eql('/test/temp')
    end
    it "defaults to system temp dir" do
      expect(Oubliette).to receive(:config).and_return({})
      expect(actor.export_temp_dir).to eql(Dir.tmpdir)
    end
  end
  
  describe "#export_temp_path" do
    it "returns export_destination when appropriate" do
      actor_attributes[:export_destination] = '/tmp/destination_file'
      expect(actor.export_temp_path).to eql('/tmp/destination_file')
    end
    it "returns a random temp file" do
      expect(actor).to receive(:export_temp_dir).and_return('/tmp/test_dir')
      expect(actor.export_temp_path).to start_with('/tmp/test_dir/')
      expect(actor.export_temp_path.length).to be > ('/tmp/test_dir/'.length + 10)
    end
  end
  
  describe "#export_temp_zip" do
    it "returns an open zip file" do
      expect(actor.export_temp_zip).to be_a(Zip::File)
    end
  end
  
  describe "#oubliette_files" do
    let(:files) { [file1, file2] }
    it "returns an enumeration of oubliette files" do
      e = actor.oubliette_files
      expect(e).to respond_to(:each)
      a = e.to_a
      expect(a).to all( be_a(Oubliette::PreservedFile) )
      expect(a.map(&:id)).to match_array([file1.id, file2.id])
    end
  end
  
  describe "#zip_files" do
    let(:files) { [file1, file2] }
    let(:file1) { FactoryGirl.create(:preserved_file, :with_file) }
    let(:file2) { FactoryGirl.create(:preserved_file, :with_file) }
    let(:zip_path) { actor.instance_variable_get(:@export_temp_zip).try(:name) }
    after {
      File.unlink(zip_path) if(zip_path.present? && File.exists?(zip_path)) 
    }
    it "zips up the files" do
      expect(actor.zip_files).to eql(true)
      expect(zip_path).to be_present
      expect(File.exists?(zip_path)).to eql(true)
      entries = { 'test1.jpg' => false, 'test1-1.jpg' => false}
      Zip::File.open(zip_path) do |zip_file|
        zip_file.each do |entry|
          expect(entries[entry.name]).to eql(false)
          entries[entry.name] = true
          expect(entry.get_input_stream.read.length).to be > 100_000
        end
      end
      expect(entries.values).to all( eql(true) )
    end
    it "returns false when something goes wrong" do
      actor.export_file_ids << 'test'
      expect(actor.zip_files).to eql(false)
    end
  end
  
  describe "#send_zip" do
    xit "sends the zip" do
    end
    # TODO: Different methods of sending, test all
  end
  
  describe "#clean_temporary_file" do
    let(:dummy_file) { Tempfile.new('export_spec').tap do |f| f.write('test'); f.close end .path }
    before { actor.instance_variable_set(:@export_temp_zip, double('temp_zip', present?: true, name: dummy_file)) }
    after { File.unlink(dummy_file) if File.exists?(dummy_file) }
    context "email export method" do
      let(:actor_attributes) { {export_method: :email, export_file_ids: files.map(&:id), export_note: export_note} }
      it "deletes temporary files" do
        actor.clean_temporary_file
        expect(File.exists?(dummy_file)).to eql(false)
      end
    end
    context "store export method" do
      let(:actor_attributes) { {export_method: :store, export_file_ids: files.map(&:id), export_note: export_note} }
      it "preserves files when using store method" do
        actor.clean_temporary_file
        expect(File.exists?(dummy_file)).to eql(true)
      end
    end
  end
  
  describe "#finish_export" do
    it "calls all methods" do
      expect(actor).to receive(:clean_temporary_file)
      expect(actor).to receive(:email_notifications)
      actor.finish_export
    end
  end
  
  describe "#email_notifications" do
    xit "mails notifications" do
      # TODO
    end
  end
  
end