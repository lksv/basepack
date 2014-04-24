# == Schema Information
#
# Table name: export_templates
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  class_type      :string(255)
#  schema_template :text
#  active          :boolean          default(FALSE), not null
#  position        :integer
#  created_at      :datetime
#  updated_at      :datetime
#

class ExportTemplate < ActiveRecord::Base
  belongs_to :user, inverse_of: :export_templates

  validates :name, presence: true,  :uniqueness => { :scope => :class_type }

  serialize :schema_template

  validates :active, inclusion: [true, false]

  default_scope -> { order 'export_templates.position ASC' }

  scope :active, -> { where(active: true) }
end
