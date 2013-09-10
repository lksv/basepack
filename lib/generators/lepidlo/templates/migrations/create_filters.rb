class CreateFilters < ActiveRecord::Migration
  def change
    create_table :filters do |t|
      t.string      :filter_type
      t.references  :user,        index: true, null: false
      t.string      :name,        default: '', null: false
      t.text        :filter,      default: '', null: false
      t.text        :description
      t.boolean     :active,      default: true
      t.integer     :position,    default: 0, null: false

      t.timestamps
    end
  end
end
