class AddColumnsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :deadline, :datetime
    add_column :projects, :color, :string
  end
end
