class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.references  :user,        index: true
      t.string      :klass,       null: false
      t.string      :file_uid,    null: false
      t.string      :file_name
      t.string      :file_mime_type
      t.integer     :file_size
      t.string      :report_uid
      t.string      :report_name
      t.string      :report_mime_type
      t.integer     :num_errors,   default: 0, null: false
      t.integer     :num_imported, default: 0, null: false
      t.string      :state,        default: "not_configured", null: false
      t.string      :action_name,  default: 'import', null: false
      t.text        :configuration
      t.timestamps
    end

    add_index :imports, [:klass, :user_id]
  end
end
