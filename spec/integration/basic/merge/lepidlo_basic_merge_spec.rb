require 'spec_helper'
include Warden::Test::Helpers
include Devise::TestHelpers

describe "Lepidlo basic merge" do
  subject { page }

  describe "diff" do
    it "shows form" do
      @customer = FactoryGirl.create(:customer) 
      @customer2 = FactoryGirl.create(:customer) 
      visit customer_path(:model_name => "customer", :id => @customer.id)
    end
  end

  describe "merge" do
    
  end

end
