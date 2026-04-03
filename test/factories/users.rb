FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "StrongPass1!" + Faker::Internet.password(min_length: 4) }
    preferred_locale { "en" }
    theme_preference { "system" }

    trait :with_avatar do
      after(:build) do |user|
        user.avatar.attach(
          io: StringIO.new("fake image"),
          filename: "avatar.jpg",
          content_type: "image/jpeg"
        )
      end
    end

    trait :admin do
      role { :admin }
    end

    trait :oauth do
      provider { "google_oauth2" }
      uid { SecureRandom.hex(10) }
    end

    trait :with_profile do
      bio { Faker::Lorem.sentence }
      instagram_username { Faker::Internet.username(specifier: 5..10, separators: %w[.]) }
      twitter_username { Faker::Internet.username(specifier: 5..10, separators: %w[_]) }
    end

    trait :portuguese do
      preferred_locale { "pt-BR" }
    end
  end
end
