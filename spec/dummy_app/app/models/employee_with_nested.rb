# == Schema Information
#
# Table name: employees
#
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  email                :string(255)
#  income               :integer
#  bonus                :boolean
#  position_id          :integer
#  created_at           :datetime
#  updated_at           :datetime
#  title                :string(255)
#  phone                :string(255)
#  position_category_id :integer
#

class EmployeeWithNested < Employee
  accepts_nested_attributes_for :account
  accepts_nested_attributes_for :position
  accepts_nested_attributes_for :projects
  accepts_nested_attributes_for :skills
end
