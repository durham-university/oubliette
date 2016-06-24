require 'rails_helper'

RSpec.describe Oubliette::FixityActor do
  
  let(:file) {
    FactoryGirl.create(:preserved_file).tap do |file| 
      allow(file).to receive(:content).and_return(content)
    end
  }
  let(:content) { double('file_content') }
  
  let(:actor){ Oubliette::FixityActor.new(file,nil) }

  describe "#notify_fixity_error" do
    let(:mail) { double('mail') }
    it "sends notifications" do
      expect(Oubliette::FixityNotificationMailer).to receive(:fixity_failed) do mail end
      expect(mail).to receive(:deliver_now)
      actor.send(:notify_fixity_error)
    end
  end
  
  describe "#finish" do
    it "saves object and log" do
      expect(file.status).not_to eql(Oubliette::PreservedFile::STATUS_PASS)
      file.preservation_log.content='test content'
      file.status = Oubliette::PreservedFile::STATUS_PASS
      actor.finish
      file.reload
      expect(file.status).to eql(Oubliette::PreservedFile::STATUS_PASS)
      expect(file.preservation_log.content).to eql('test content')
    end
  end

  describe "#fedora_fixity!" do
    before { allow(actor).to receive(:notify_fixity_error) }
    
    it "checks fixity" do
      expect(content).to receive(:check_fixity).and_return(true)
      expect(actor.fedora_fixity!).to eql(true)
      expect(file.preservation_log.content).to be_present
      expect(file.preservation_log.content).not_to include('fixity error')
    end
    
    context "when fixity check fails" do
      it "logs error and sends notifications" do
        expect(content).to receive(:check_fixity).and_return(false)
        expect(actor).to receive(:notify_fixity_error)
        expect(actor.fedora_fixity!).to eql(false)
        expect(file.preservation_log.content).to include('fixity error')
      end
    end
  end
  
  describe "#ingestion_fixity!" do
    before { allow(actor).to receive(:notify_fixity_error) }

    it "checks fixity" do
      expect(file).to receive(:check_ingestion_fixity).and_return(true)
      expect(actor.ingestion_fixity!).to eql(true)
      expect(file.preservation_log.content).to be_present
      expect(file.preservation_log.content).not_to include('fixity error')
    end
    
    context "when fixity check fails" do
      it "logs error and sends notifications" do
        expect(file).to receive(:check_ingestion_fixity).and_return(false)
        expect(actor).to receive(:notify_fixity_error)
        expect(actor.ingestion_fixity!).to eql(false)
        expect(file.preservation_log.content).to include('fixity error')
      end
    end
  end

end