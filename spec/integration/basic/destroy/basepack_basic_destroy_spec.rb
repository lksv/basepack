require "spec_helper"

describe "Basepack Basic Destroy" do
  let(:employee) { FactoryGirl.create(:employee) }

  describe "destroy from show" do
    before(:each) do
      visit employee_path(employee)
    end

    it "destroys an object" do
      expect {
        click_on "Delete"
      }.to change(Employee, :count).by(-1)
      expect(page).to have_content("Employee successfully deleted")
    end

    context "when successfully destroyed" do
      it "redirects to index" do
        click_on "Delete"
        expect(current_path).to eq employees_path
      end
    end

    context "when not destroyed" do
      it "redirects back to the object" do
        pending "It should redirect to show page when object can not be destroyed and display failure flash messages"
        # currently it is displaying successful message even when object wasn't destroyed!! 
        
        # show some error in base
        Employee.any_instance.stub(:errors).and_return(['error'])
        allow_any_instance_of(Employee).to receive(:destroy_hook).and_return false
        click_on "Delete"
        expect(current_path).to eq employee_path(employee)
        expect(page).to have_content("Employee failed to be deleted")
      end
    end
  end

  describe "destroy from list" do
    before(:each) do
      employee
      visit employees_path
    end

    it "destroys an object" do
      expect {
        click_on "Delete"
      }.to change(Employee, :count).by(-1)
      expect(page).to have_content("Employee successfully deleted")
      expect(current_path).to eq employees_path
    end
  end

  describe "destroy missing object" do
    it "does nothing" do
      page.driver.submit :delete, "/employees/254-non-existing-id", {}
      expect(page.driver.status_code).to_not eq 200
    end
  end
end
