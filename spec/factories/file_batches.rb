FactoryGirl.define do
  factory :file_batch, class: Oubliette::FileBatch do
    sequence(:title) { |n| "Test file batch #{n}" }
    sequence(:note) { |n| "note #{n}" }

    trait :with_files do
      ordered_members {
        [ FactoryGirl.build(:preserved_file), FactoryGirl.build(:preserved_file) ]
      }
    end
  end
end
