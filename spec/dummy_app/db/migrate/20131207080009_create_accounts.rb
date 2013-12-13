class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :account_number
      t.belongs_to :employee, index: true

      t.timestamps
    end
  end
end
