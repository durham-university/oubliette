module Oubliette
  class FixityActor < Oubliette::BaseActor

    attr_accessor :fedora_retry_count
    attr_accessor :retry_delay
    attr_accessor :retry_jitter

    def initialize(model_object, user=nil, attributes={})
      super
      @fedora_retry_count = self.attributes.fetch(:fedora_retry_count, 10)
      @retry_delay = self.attributes.fetch(:retry_delay, 5.0)
      @retry_jitter = self.attributes.fetch(:retry_jitter, 5.0)
    end
                
    def fedora_fixity!
      log!("Verifying Fedora fixity of #{object_label}")

      #model_object.content.check_fixity ? pass_file('Fedora') : fail_file("Fedora")
      
      # Following is a work around of a bug in Fedora. If two fixity checks are performed at the
      # same time, they will both come back as fails. Very likely the files are actually fine. So just
      # retry it a few times.

      retry_counter = 0
      pass = model_object.content.check_fixity
      while !pass && retry_counter < fedora_retry_count
        log!(:info, "Retrying Fedora fixity check.")
        retry_counter += 1
        sleep(retry_delay + rand*retry_jitter)
        pass = model_object.content.check_fixity
      end
      
      pass ? pass_file('Fedora') : fail_file("Fedora")      
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