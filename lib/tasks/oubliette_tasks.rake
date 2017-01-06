namespace :oubliette do
  desc "run fixity check on all files"
  task "fixity_all" => :environment do
    if Oubliette::FixityJob.new(file_limit: -1).queue_job
      puts "Successfully queued FixityJob of all files"
      true
    else
      puts "Unable to queue FixityJob"
      false
    end
  end
  
  desc "run fixity check on some files"
  task "fixity" => :environment do
    if Oubliette::FixityJob.new.queue_job
      puts "Successfully queued FixityJob"
      true
    else
      puts "Unable to queue FixityJob"
      false
    end
  end
end
