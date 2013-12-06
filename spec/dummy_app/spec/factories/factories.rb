require 'faker'

FactoryGirl.define do
  factory :employee do
    name { Faker::Name.name }
    email { Faker::Internet.email }
  end

  factory :position do
    name { Faker::Name.title }
  end

  factory :task do
    sequence :name do |n| 
      "task #{n}"
    end
  end
end
