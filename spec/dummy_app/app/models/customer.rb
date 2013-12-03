# == Schema Information
#
# Table name: customers
#
#  id         :integer          not null, primary key
#  email      :string(255)
#  name       :string(255)
#  active     :boolean
#  group_id   :integer
#  created_at :datetime
#  updated_at :datetime
#

class Customer < ActiveRecord::Base
  belongs_to :group, inverse_of: :customers
  has_many :comments, inverse_of: :customer
end
