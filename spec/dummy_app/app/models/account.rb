class Account < ActiveRecord::Base
  belongs_to :employee, inverse_of: :account
end
