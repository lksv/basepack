class Account < ActiveRecord::Base
  belongs_to :employee, inverse_of: :account

  def to_label
    "Account " + account_number.to_s
  end
end
