# == Schema Information
#
# Table name: tasks
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

class Task < ActiveRecord::Base
  belongs_to :employee, inverse_of: :tasks
  # validates_presence_of :name

  def to_label
    self.description
  end
end
