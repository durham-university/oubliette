module Oubliette
  class FixityNotificationMailer < OublietteMailer
    def fixity_failed(actor)
      recipients = notification_recipients(actor)
      if recipients.present?
        actor.log!("Sending notifications to #{recipients.join('; ')}")
        @actor = actor
        subject = "[Oubliette] Fixity check FAILED"
        mail(to: recipients, subject: subject)
      else
        actor.log!("No email notification recipients defined.")
      end
    end
    
    def notification_recipients(actor)
      (Oubliette.config['notification_email_to'] || []) + ([actor.user.try(:email)].compact)
    end
  end
end
