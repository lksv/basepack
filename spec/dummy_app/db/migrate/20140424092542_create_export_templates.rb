class CreateExportTemplates < ActiveRecord::Migration
  def change
    create_table :export_templates do |t|
      t.string :name
      t.belongs_to :user, index: true
      t.string :class_type
      t.text :schema_template
      t.boolean :active, null: false, default: false
      t.integer :position

      t.timestamps
    end
  end
end
