require 'faker'

FactoryGirl.define do
  factory :employee do
    name { Faker::Name.name }
    email { Faker::Internet.email }

    factory :employee_with_all_associations do
      account   { FactoryGirl.build(:account) }
      position  { FactoryGirl.build(:position) }
      projects  { FactoryGirl.build_list(:project_with_tasks, 2) }
      skills    { FactoryGirl.build_list(:skill, 2) }
    end

  end

  factory :position do
    name              { Faker::Name.title }
  end

  factory :project do
    sequence(:name)   { |n| "project #{n}"}
    factory :project_with_tasks do
      tasks           { FactoryGirl.build_list(:task, 2) }
    end
  end

  factory :task do
    sequence(:name)   { |n| "task #{n}" }
    description       { Faker::Lorem.sentence }
  end

  factory :account do
    account_number    Faker::Number.number(3)
  end

  factory :skill do
    sequence(:name)   { |n| "skill#{n}" }
  end
end
