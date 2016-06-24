require "rails_helper"

RSpec.describe Oubliette::FixityNotificationMailer, type: :mailer do
  let(:user) { FactoryGirl.create(:user) }
  let(:file_title) { 'Test File' }
  let(:actor) {
    Oubliette::FixityActor.new(Oubliette::PreservedFile.new(title: file_title), user).tap do |actor|
      actor.log!(:info, "Verifying Fedora fixity of o0ab12cd34x")
      actor.log!(:error, "Fedora fixity error in o0ab12cd34x")
    end
  }

  before {
    allow(Oubliette).to receive(:config).and_return({
      'notification_email_to' => ['user1@example.com', 'user2@example.com'],
      'notification_email_from' => 'test@example.com'
    })
  }

  describe "#fixity_failed" do
    let(:mail) { Oubliette::FixityNotificationMailer.fixity_failed(actor) }
    it "sets the subject" do
      expect(mail.subject).to include('FAILED')
    end
    describe "body" do
      it "has file name and status" do
        expect(mail.body.encoded).to include(file_title)
        expect(mail.body.encoded).to include('FAILED')
      end
      it "has the log" do
        expect(mail.body.encoded).to include(actor.log.first.to_full_s)
        expect(mail.body.encoded).to include(actor.log.last.to_full_s)
      end
    end
  end
  
  describe "#notification_recipients" do
    let(:recipients) { Oubliette::FixityNotificationMailer.send(:new).notification_recipients(actor) }
    it "returns configured admin users" do
      expect(recipients).to include('user1@example.com')
      expect(recipients).to include('user2@example.com')
    end
    it "returns actor user" do
      expect(actor.user.email).to be_present
      expect(recipients).to include(actor.user.email)
    end
  end
end
