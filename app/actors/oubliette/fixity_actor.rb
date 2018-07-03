module Oubliette
  class FixityActor < Oubliette::BaseActor
                
    def fedora_fixity!
      log!("Verifying Fedora fixity of #{object_label}")
      model_object.content.check_fixity ? pass_file('Fedora') : fail_file("Fedora")
    end
    
    def ingestion_fixity!
      log!("Verifying ingestion fixity of #{object_label}")
      model_object.check_ingestion_fixity ? pass_file("Ingestion") : fail_file("Ingestion")
    end
    
    def log!(*args)
      preservation_log!(*args)
      super(*args)
    end
    
    def finish
      model_object.preservation_log.save
      model_object.save
    end
        
    private
    
      def preservation_log!(*args)
        msg = DurhamRails::Log::LogMessage.new(*args)
        s = msg.to_full_s + "\n"
        model_object.preservation_log.content = model_object.preservation_log.content.to_s + s
      end
    
      def object_label
        model_object.id.to_s
      end
      
      def notify_fixity_error
        # mailer adds a log message
        mail = Oubliette::FixityNotificationMailer.fixity_failed(self)
        mail.deliver_now unless mail.nil? # For some strange reason, this doesn't work as mail.try(:deliver_now)
        true
      end
      
      def pass_file(fixity_type)
        log!("#{fixity_type} fixity intact")
        model_object.check_date = DateTime.now
        model_object.status = Oubliette::PreservedFile::STATUS_PASS
        true
      end
      
      def fail_file(fixity_type)
        log!(:error, "#{fixity_type} fixity error in #{object_label}")
        notify_fixity_error
        model_object.check_date = DateTime.now
        model_object.status = Oubliette::PreservedFile::STATUS_ERROR
        false
      end    
    
  end
end