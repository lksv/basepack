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

require 'spec_helper'

describe Customer do
  #pending "add some examples to (or delete) #{__FILE__}"
end
