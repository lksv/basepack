class ChangeTasksAssociations < ActiveRecord::Migration
  def change
    rename_column :tasks, :employee_id, :project_id
  end
end
