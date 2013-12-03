class Comment < ActiveRecord::Base
  belongs_to :customer, inverse_of: :comments

  def to_label
    self.body
  end
end
