require 'faker'

FactoryGirl.define do
  factory :employee do
    name { Faker::Name.name }
    email { Faker::Internet.email }
  end

  factory :position do
    name { Faker::Name.title }
  end

  factory :project do
    sequence(:name) { |n| "project #{n}"}
  end

  factory :task do
    sequence(:name) { |n| "task #{n}" }
    description { Faker::Lorem.sentence }
  end

  factory :account do
    account_number Faker::Number.number(3)
  end

  factory :skill do
    name "skill"
  end
end
