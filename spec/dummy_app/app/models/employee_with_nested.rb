class EmployeeWithNested < Employee
  accepts_nested_attributes_for :account
  accepts_nested_attributes_for :position
  accepts_nested_attributes_for :projects
  accepts_nested_attributes_for :skills
end
