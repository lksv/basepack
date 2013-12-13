class CreateEmployees < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.string :name
      t.string :email
      t.integer :income
      t.boolean :bonus
      t.belongs_to :position, index: true

      t.timestamps
    end
  end
end
