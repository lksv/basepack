# == Schema Information
#
# Table name: positions
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Position < ActiveRecord::Base
  has_many :employees, inverse_of: :position
end
