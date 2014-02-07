# == Schema Information
#
# Table name: positions
#
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  position_category_id :integer
#

class Position < ActiveRecord::Base
  has_many :employees, inverse_of: :position
  belongs_to :position_category, class_name: "PositionCategory", inverse_of: :positions
end
