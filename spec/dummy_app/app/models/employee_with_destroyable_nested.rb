class EmployeeWithDestroyableNested < Employee
  accepts_nested_attributes_for :account, allow_destroy: true
  accepts_nested_attributes_for :position, allow_destroy: true
  accepts_nested_attributes_for :projects, allow_destroy: true
  accepts_nested_attributes_for :skills, allow_destroy: true
end
