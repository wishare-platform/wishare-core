FactoryBot.define do
  factory :notification do
    user
    notification_type { :invitation_received }
    association :notifiable, factory: :invitation
    data { { "sender_name" => "Test User" } }
    read { false }

    trait :read do
      read { true }
    end

    trait :item_purchased do
      notification_type { :item_purchased }
      association :notifiable, factory: :wishlist_item
      data { { "purchaser_name" => "Friend", "item_name" => "Gift" } }
    end
  end
end
