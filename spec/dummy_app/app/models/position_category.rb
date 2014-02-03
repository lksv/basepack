# == Schema Information
#
# Table name: position_categories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class PositionCategory < ActiveRecord::Base
  has_many :positions, class_name: "Position", foreign_key: "position_category_id", inverse_of: :position_category
  has_many :employees, class_name: "Employee", foreign_key: "position_category_id", inverse_of: :position_category
end
