FactoryBot.define do
  factory :wishlist do
    user
    name { Faker::Commerce.department }
    visibility { :publicly_visible }
    event_type { "none" }

    trait :private do
      visibility { :private_list }
    end

    trait :friends_only do
      visibility { :partner_only }
    end

    trait :birthday do
      event_type { "birthday" }
      event_date { 30.days.from_now }
    end

    trait :wedding do
      event_type { "wedding" }
      event_date { 90.days.from_now }
    end

    trait :past_event do
      event_type { "birthday" }
      event_date { 10.days.ago }
    end

    trait :with_items do
      after(:create) do |wishlist|
        create_list(:wishlist_item, 3, wishlist: wishlist)
      end
    end
  end
end
