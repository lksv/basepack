# == Schema Information
#
# Table name: projects
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  employee_id :integer
#  created_at  :datetime
#  updated_at  :datetime
#  deadline    :datetime
#  color       :string(255)
#

class Project < ActiveRecord::Base
  belongs_to :employee, inverse_of: :projects
  has_many :tasks, inverse_of: :project

  acts_as_taggable
  
  # rails_admin do
  #   show do
  #     field :tags
  #   end

  #   edit do
  #     field :description, :wysihtml5
  #     field :deadline, :datetime
  #     field :tag_list do
  #       partial 'tag_list_with_suggestions'
  #     end
  #     # field :color, :colorpicker
  #     exclude_fields :base_tags, :tags
  #     include_all_fields
  #   end
  # end
end
