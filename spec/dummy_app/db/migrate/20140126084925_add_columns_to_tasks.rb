class AddColumnsToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :status, :string
    add_column :tasks, :completed_percents, :integer
  end
end
