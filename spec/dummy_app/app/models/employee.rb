# == Schema Information
#
# Table name: employees
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  email       :string(255)
#  income      :integer
#  bonus       :boolean
#  position_id :integer
#  created_at  :datetime
#  updated_at  :datetime
#

class Employee < ActiveRecord::Base
  belongs_to :position, inverse_of: :employees
  has_many :tasks, inverse_of: :employee
  has_one :account, inverse_of: :employee
end
