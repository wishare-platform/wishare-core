FactoryBot.define do
  factory :wishlist_item do
    wishlist
    name { Faker::Commerce.product_name }
    priority { :medium }
    status { :available }
    currency { "USD" }
    price { Faker::Commerce.price(range: 10.0..500.0) }

    trait :purchased do
      status { :purchased }
      association :purchased_by, factory: :user
    end

    trait :reserved do
      status { :reserved }
    end

    trait :with_url do
      url { "https://example.com/product/#{SecureRandom.hex(4)}" }
    end

    trait :brl do
      currency { "BRL" }
    end

    trait :eur do
      currency { "EUR" }
    end

    trait :jpy do
      currency { "JPY" }
      price { 15000 }
    end
  end
end
