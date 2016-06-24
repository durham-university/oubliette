module Oubliette
  # Preview all emails at http://localhost:3000/rails/mailers/oubliette/fixity_notification_mailer
  class FixityNotificationMailerPreview < ActionMailer::Preview
    def fixity_failed
      Oubliette::FixityNotificationMailer.fixity_failed( actor )
    end

    private

      def actor
        Oubliette::FixityActor.new(Oubliette::PreservedFile.new(title: 'Test file', id: 'o0ab12cd34x'), User.new(email: 'test@example.com')).tap do |actor|
          actor.instance_variable_set(:@batch_status,true)
          actor.log!(:info, "Verifying Fedora fixity of o0ab12cd34x")
          actor.log!(:error, "Fedora fixity error in o0ab12cd34x")
        end
      end

  end
end
