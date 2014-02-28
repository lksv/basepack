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
#  ancestry    :string(255)
#  position    :integer
#  deadline    :datetime
#  color       :string(255)
#

class Project < ActiveRecord::Base
  belongs_to :employee, inverse_of: :projects
  has_many :tasks, inverse_of: :project

  acts_as_taggable

  has_ancestry

  before_validation :strip_ancestry

  private

  def strip_ancestry
    self.ancestry = nil if self.ancestry == ''
  end
end
