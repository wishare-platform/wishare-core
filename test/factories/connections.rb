FactoryBot.define do
  factory :connection do
    user
    association :partner, factory: :user
    status { :pending }

    trait :accepted do
      status { :accepted }
    end

    trait :declined do
      status { :declined }
    end
  end
end
