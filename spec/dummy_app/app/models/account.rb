# == Schema Information
#
# Table name: accounts
#
#  id             :integer          not null, primary key
#  account_number :integer
#  employee_id    :integer
#  created_at     :datetime
#  updated_at     :datetime
#

class Account < ActiveRecord::Base
  belongs_to :employee, inverse_of: :account

  def to_label
    "Account " + account_number.to_s
  end
end
