class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :email
      t.string :name
      t.boolean :active
      t.references :group, index: true

      t.timestamps
    end
  end
end
