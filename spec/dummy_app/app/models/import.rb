# == Schema Information
#
# Table name: imports
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  klass            :string(255)      not null
#  file_uid         :string(255)      not null
#  file_name        :string(255)
#  file_mime_type   :string(255)
#  file_size        :integer
#  report_uid       :string(255)
#  report_name      :string(255)
#  report_mime_type :string(255)
#  num_errors       :integer          default(0), not null
#  num_imported     :integer          default(0), not null
#  state            :string(255)      default("not_configured"), not null
#  action_name      :string(255)      default("import"), not null
#  configuration    :text
#  created_at       :datetime
#  updated_at       :datetime
#

class Import < ActiveRecord::Base
  include Basepack::Import::ModelDragonfly

  belongs_to :user, inverse_of: :imports

  handle_asynchronously :import_data

  RailsAdmin.config do
    Basepack::Utils.model_config(Import).show.field :user
  end
end
