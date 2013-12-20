class AddTitleToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :title, :string
  end
end
