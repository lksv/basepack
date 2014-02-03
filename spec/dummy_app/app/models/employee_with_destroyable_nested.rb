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

class EmployeeWithDestroyableNested < Employee
  accepts_nested_attributes_for :account, allow_destroy: true
  accepts_nested_attributes_for :position, allow_destroy: true
  accepts_nested_attributes_for :projects, allow_destroy: true
  accepts_nested_attributes_for :skills, allow_destroy: true
end
