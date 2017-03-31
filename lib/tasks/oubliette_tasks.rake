namespace :oubliette do
  desc "run fixity check on all files"
  task "fixity_all" => :environment do
    if Oubliette::FixityJob.new(file_limit: -1, time_limit: -1).queue_job
      puts "Successfully queued FixityJob of all files"
      true
    else
      puts "Unable to queue FixityJob"
      false
    end
  end
  
  desc "run fixity check on some files"
  task "fixity", [:file_limit,:time_limit] => :environment do |t,args|
    file_limit = args[:file_limit].try(:to_i) || 500
    time_limit = args[:time_limit].try(:to_i) || 30
    if Oubliette::FixityJob.new(file_limit: file_limit, time_limit: time_limit).queue_job
      puts "Successfully queued FixityJob"
      true
    else
      puts "Unable to queue FixityJob"
      false
    end
  end
end
