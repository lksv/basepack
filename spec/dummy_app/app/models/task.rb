# == Schema Information
#
# Table name: tasks
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  project_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#

class Task < ActiveRecord::Base
  belongs_to :project, inverse_of: :tasks
  # validates_presence_of :name

  def to_label
    self.description
  end
end
