class CreatePositionCategories < ActiveRecord::Migration
  def change
    create_table :position_categories do |t|
      t.string :name

      t.timestamps
    end
  end
end
