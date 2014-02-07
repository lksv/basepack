# == Schema Information
#
# Table name: employees
#
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  email                :string(255)
#  income               :integer
#  bonus                :boolean
#  position_id          :integer
#  created_at           :datetime
#  updated_at           :datetime
#  title                :string(255)
#  phone                :string(255)
#  position_category_id :integer
#

class Employee < ActiveRecord::Base
  include Basepack::Import::Importable

  belongs_to :position, inverse_of: :employees
  belongs_to :position_category, class_name: "PositionCategory", inverse_of: :employees

  has_many :projects, inverse_of: :employee
  has_many :tasks, through: :projects
  has_one :account, inverse_of: :employee
  has_and_belongs_to_many :skills

  validates_presence_of :name, :email
  validates_uniqueness_of :email, on: :create, message: "must be unique"
  validate :is_allowed?, :on => :create

  before_destroy :destroy_hook

=begin
  rails_admin do
    list do
      bulk_actions true
    end

    edit do
      field :projects
      field :tasks do
        options_source_params do
          { "f[project_id_in]" => bindings[:object].try(:project_ids) || [-1] }
        end
        html_attributes do
        { data: { 
          # set project's field as dependent select box
          "dependant-filteringselect" => "field=project_ids",

          # post parameters
          "dependant-param" => "f[project_id_in]" }
        }
        end
      end
      
      field :position_category
      field :position do
        options_source_params do
          { "f[position_category_id_eq]" => bindings[:object].try(:project_category) || -1 }
        end

        html_attributes do
        { data: { 
          # set project's field as dependent select box
          "dependant-filteringselect" => "field=position_category_id",

          # post parameters
          "dependant-param" => "f[position_category_id_eq]" }
        }
        end
      end

      field :name
      field :email
      field :income
      field :bonus
      field :account
      field :title
      field :phone
      field :skills
    end
  end
=end

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
end
