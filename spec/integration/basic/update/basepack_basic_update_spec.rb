 require 'spec_helper'

describe "Basepack basic list" do
  # subject { page }

  let!(:employee1) { FactoryGirl.create :employee }
  #let(:ability) { Object.new.extend(CanCan::Ability) }

  describe "update" do

   it "does not allow to change id" do
     employee1.id
     new_id = 10000
     page.driver.submit :put, "/employees/#{employee1.id}", { employee: { id: new_id } }
     expect(page.driver.status_code).to eq 200

     expect(Employee.exists?(new_id)).to be_false
     expect(Employee.exists?(employee1.id)).to be_true
    end

  end

  #TODO (except others things not forgot to test):
  # form with accepts_nested_attributes_for
  #   * without :allow_destroy -- test that ignore :_destroy param
  #   * with :update_only  -- test that ignore :id param
  #  ...test for:
  #   * creates new nested items
  #   * modify existing nested items
  #   * delete nested items

end
