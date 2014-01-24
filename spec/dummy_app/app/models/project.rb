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
#

class Project < ActiveRecord::Base
  belongs_to :employee, inverse_of: :projects
  has_many :tasks, inverse_of: :project

  has_ancestry
end
