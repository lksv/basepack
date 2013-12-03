class CreateComment < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :body
      t.references :customer, index: true

      t.timestamps
    end
  end
end
