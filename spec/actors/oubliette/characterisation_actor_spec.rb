require 'rails_helper'

RSpec.describe Oubliette::CharacterisationActor do
  
  let(:file) {
    FactoryGirl.create(:preserved_file).tap do |file| 
      file.content.instance_variable_set(:@content, content_inst) if content_inst
      allow(file.content).to receive(:content).and_return(content)
      allow(file.content).to receive(:original_name).and_return(original_name)
    end
  }
  let(:content_inst) { nil }
  let(:content) { 'dummy content' }
  let(:original_name) { 'test.txt' }
  let(:characterisation) { Nokogiri::XML('<fits><test/></fits>') }
  
  let(:actor){ Oubliette::CharacterisationActor.new(file,nil) }
  
  describe "#characterisation" do
    context "with file instance variable" do
      let(:content_inst) { OpenStruct.new(path: '/tmp/moo') }
      it "characterises with existing file" do
        expect(actor).to receive(:run_fits).with('/tmp/moo').and_return([characterisation,'',0])
        expect(actor.characterisation).to eql(characterisation)
      end
    end
    context "with no instance variable" do
      let(:content_io) { StringIO.new(content)}
      it "runs fits on the io object" do
        expect(file).to receive(:content_io).and_return(content_io)
        expect(actor).to receive(:run_fits_io).with(content_io, original_name).and_return([characterisation,'',0])
        expect(actor.characterisation).to eql(characterisation)
      end
    end
  end
  
  describe "#set_characterisation" do
    before {
      allow(actor).to receive(:characterisation).and_return(characterisation)
    }
    it "sets characterisation and saves" do
      expect(file).to receive(:save).and_call_original
      actor.set_characterisation
      file.reload
      expect(file.characterisation.content).to eql(characterisation.to_s)
    end
  end

end