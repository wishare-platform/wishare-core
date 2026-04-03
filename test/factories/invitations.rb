FactoryBot.define do
  factory :invitation do
    association :sender, factory: :user
    recipient_email { Faker::Internet.unique.email }
    status { :pending }

    trait :accepted do
      status { :accepted }
      accepted_at { Time.current }
    end

    trait :expired do
      status { :expired }
      created_at { 8.days.ago }
    end
  end
end
