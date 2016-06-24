namespace :oubliette do
  desc "run fixity check on all files"
  task "fixity_all" => :environment do
    if Oubliette::FixityJob.new.queue_job
      puts "Successfully queued FixityJob"
      true
    else
      puts "Unable to queue FixityJob"
      false
    end
  end
end
