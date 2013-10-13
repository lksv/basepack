require 'faker'

FactoryGirl.define do
  factory :customer do
    email Faker::Internet.email
    name Faker::Name.name
  end
end
