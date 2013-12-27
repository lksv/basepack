 require 'spec_helper'

describe "Basepack basic update" do
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

  #context "without accepts_nested_attributes_for" do
  #  it "do not allow to accepts id and _delete params" do
  #    pending '...'
  #  end
  #end

  #context "with accepts_nested_attributes_for" do
  #  let(:employee_wih_nested) { FactoryGirl.create(:employee_with_all_associations) }
  #  it "updates nested form fields" do
  #    visit edit_employee_with_nested(employee_wih_nested)
  #  end

  #  it "adds nested form items" do
  #  end

  #  it "deletes nested form items" do
  #  end

  #  #it "crea

  #end

  #TODO (except others things not forgot to test):
  # form with accepts_nested_attributes_for
  #   * without :allow_destroy -- test that ignore :_destroy param
  #   * with :update_only  -- test that ignore :id param
  #  ...test for:
  #   * creates new nested items
  #   * modify existing nested items
  #   * delete nested items

end
