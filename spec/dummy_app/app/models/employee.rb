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
#  title       :string(255)
#

class Employee < ActiveRecord::Base
  belongs_to :position, inverse_of: :employees
  has_many :projects, inverse_of: :employee
  has_many :tasks, through: :projects
  has_one :account, inverse_of: :employee
  has_and_belongs_to_many :skills

  validates_presence_of :name, :email
  validates_uniqueness_of :email, on: :create, message: "must be unique"
  validate :is_allowed?, :on => :create

  before_destroy :destroy_hook

  def destroy_hook; end

  def name_with_title
    "#{title} #{name}"
  end

  def is_allowed?
    # black list
    is_allowed = ["forbidden@mail.com"].exclude?(email)
    errors[:base] << "This email is forbidden." unless is_allowed
    is_allowed
  end

  def account_id
    self.account.try(:id)
  end

  def account_id=(id)
    self.account = Account.find_by(id: id)
  end

  rails_admin do
    list do
      bulk_actions true
    end
  end

end
