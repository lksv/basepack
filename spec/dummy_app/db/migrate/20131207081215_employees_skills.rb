class EmployeesSkills < ActiveRecord::Migration
  def change
    create_table 'employees_skills', id: false do |t|
      t.integer :employee_id
      t.integer :skill_id
    
      t.timestamps
    end
  end
end
