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

    factory :employee_with_projects do
      projects  { FactoryGirl.build_list(:project_with_tasks, 2) }
    end
    
    factory :employee_with_skills do
      skills    { FactoryGirl.build_list(:skill, 2) }
    end
    
    # factory :employee_with_account do
    #   account { FactoryGirl.build(:account) }
    # end

  end

  factory :position do
    name              { Faker::Name.title }
  end

  factory :position_category do
    name              { Faker::Commerce.department }

    factory :category_with_positions do
      positions  { FactoryGirl.build_list(:position, 2) }
    end
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
