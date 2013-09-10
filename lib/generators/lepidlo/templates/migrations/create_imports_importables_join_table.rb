class CreateImportsImportablesJoinTable < ActiveRecord::Migration
  def change
    create_table :imports_importables do |t|
      t.references :import
      t.references :importable, polymorphic: true
    end
    add_index :imports_importables, :import_id
    add_index :imports_importables, :importable_id
  end
end
