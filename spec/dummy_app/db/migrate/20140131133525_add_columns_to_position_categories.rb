class AddColumnsToPositionCategories < ActiveRecord::Migration
  def change
    add_column :employees, :position_category_id, :integer
    add_column :positions, :position_category_id, :integer
  end
end
