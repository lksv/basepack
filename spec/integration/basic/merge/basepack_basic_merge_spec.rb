require 'spec_helper'

describe "Basepack basic merge", type: :request do
  # subject { page }

  describe "diff" do
    it "shows form" do
      @employee = FactoryGirl.create(:employee)
      @employee2 = FactoryGirl.create(:employee)
      visit employee_path(:model_name => "employee", :id => @employee.id)
    end
  end

  describe "merge" do

  end

end
