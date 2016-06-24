module Oubliette
  class OublietteMailer < ActionMailer::Base
    default from: Oubliette.config['notification_email_from']
    layout 'oubliette/mailer'
  end
end
