FactoryGirl.define do
  factory :preserved_file, class: Oubliette::PreservedFile do
    sequence(:title) { |n| "Test file #{n}" }
    sequence(:note) { |n| "note #{n}" }
    status Oubliette::PreservedFile::STATUS_NOT_CHECKED

    after(:build) { |file,evaluator|
      file.ingestion_log = ActiveFedora::File.new
      file.ingestion_log.content = 'Ingested through factory girl'
    }

    trait :with_file do
      after(:build) { |file,evaluator|
        file.content = ActiveFedora::File.new
        file.content.content = fixture('test1.jpg')
        file.content.original_name = 'test1.jpg'
        file.content.mime_type = 'image/jpeg'
      }
    end

    trait :with_preservation_log do
      after(:build) { |file,evaluator|
        file.preservation_log = ActiveFedora::File.new
        file.preservation_log.content = 'Preservation log contents'
      }
    end
  end
end
