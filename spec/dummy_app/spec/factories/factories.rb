require 'faker'

FactoryGirl.define do
  factory :customer do
    email { Faker::Internet.email }
    name { Faker::Name.name }
  end

  factory :group do
    name { Faker::Commerce.department }
  end
end
