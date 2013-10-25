# == Schema Information
#
# Table name: filters
#
#  id          :integer          not null, primary key
#  filter_type :string(255)
#  user_id     :integer          not null
#  name        :string(255)      default(""), not null
#  filter      :text             default(""), not null
#  description :text
#  active      :boolean          default(TRUE)
#  position    :integer          default(0), not null
#  created_at  :datetime
#  updated_at  :datetime
#

class Filter < ActiveRecord::Base

  belongs_to :user, inverse_of: :filters

  validates :name,          presence: true,  :uniqueness => { :scope => :filter_type }
  validates :user, :filter, presence: true

  validates :active, inclusion: [true, false]

  default_scope -> { order 'filters.position ASC' }

  scope :active, -> { where(active: true) }

  strip_attributes :collapse_spaces => true

  # exec the filter and resturns the collection

  def results(scope, current_ability, filterql_options = {})
   resource_class = self.filter_type.constantize
   resource_filter, filtered_scope = Lepidlo::Utils.filter(
     scope,
     { ql: self.filter },
     Lepidlo::Utils.model_config(resource_class),
     {
       auth_object: current_ability,
       filterql_options: filterql_options
     }
   )
   raise resource_filter.errors[:base] if resource_filter.errors[:base]

   #[resource_filter, filtered_scope]
   filtered_scope
  end

  rails_admin do
    list do
      field :active
      field :name
      field :filter
      field :filter_type
      field :user
    end

    show do
      field :active
      field :name
      field :description
      field :filter
      field :filter_type
      field :position
      field :user
    end

    edit do
      field :active
      field :name
      field :description
      field :filter
      field :filter_type
      field :position
      field :user do
        visible do
          bindings[:view].current_user.has_role? :admin
        end
      end
    end
  end
end
