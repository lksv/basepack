# == Schema Information
#
# Table name: tasks
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  description        :text
#  project_id         :integer
#  created_at         :datetime
#  updated_at         :datetime
#  status             :string(255)
#  completed_percents :integer
#

class Task < ActiveRecord::Base
  belongs_to :project, inverse_of: :tasks
  # validates_presence_of :name

  # rails_admin do
  #   edit do
  #     # field :status, :enum do
  #     field :name
  #     field :description

  #     field :status, :enum do
  #       html_attributes do
  #       { 
  #         data: { 
  #           "dynamic-fields" => [
  #             { condition: ["Postponed", "Done"], field_actions: { completed_percents: { visible: false }} },
  #             { condition: ["In progress"], field_actions: { completed_percents: { visible: true  }} },
  #           ]   
  #         }   
  #       }   
  #       end
  #     end

  #     field :completed_percents
  #     field :project
  #   end
  # end

  def to_label
    self.description
  end

  def status_enum
    ["Postponed", "In progress", "Done"]
  end
end
