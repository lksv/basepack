require 'spec_helper'

describe "RailsAdmin Basic Create" do

  describe "create without association" do

    it "creates an object with correct attributes" do
      visit new_employee_path
      fill_in "employee[name]", with: "John Smith"
      fill_in "employee[email]", with: "john.smith@gmail.com"
      fill_in "employee[income]", with: "1500"
      click_on "Save"

      expect(page).to have_content("Employee successfully created")
      created_employee = Employee.last
      expect(current_path).to eq employee_path(created_employee)

      expect(created_employee.name).to eq("John Smith")
      expect(created_employee.email).to eq("john.smith@gmail.com")
      expect(created_employee.income).to eq(1500)
    end
  end

  describe "create with belongs_to association", js: true do
    it "correct object" do
      pending "basepack helper can't find input[type=text]"
      position = FactoryGirl.create :position, name: "My position"
      visit new_employee_path
      fill_in "employee[name]", with: "John Smith"
      fill_in "employee[email]", with: "john.smith@gmail.com"
      add_select2 'Position', with: position.to_label 
      click_on "Save"

      @created_employee = Employee.last
      position.reload
      expect(@created_employee.position).to eq(@position)
    end
  end

  describe "create has_many associations", js: true do
    let(:project1) { FactoryGirl.create(:project) }
    let(:project2) { FactoryGirl.create(:project) }

    before(:each) do
      project1
      project2
      visit new_employee_path

      fill_in "employee[name]", with: "John Smith"
      fill_in "employee[email]", with: "john.smith@gmail.com"
      add_select2 "Projects", with: project1.to_label
    end

    it "adds project" do
      click_on "Save"
      
      created_employee = Employee.last
      expect(created_employee.project_ids).to include(project1.id) 
    end

    it "adds projects" do
      add_select2 "Projects", with: project2.to_label
      click_on "Save"
      
      created_employee = Employee.last
      expect(created_employee.project_ids).to eq [project1.id, project2.id]
    end

    it "removes project" do
      # remove_all_select2 "Projects"
      remove_select2 "Projects", with: project1.to_label

      click_on "Save"
      
      created_employee = Employee.last
      expect(created_employee.project_ids).to be_empty
    end
  end


  describe "create has_many associations", js: true do
    let(:skill1) { FactoryGirl.create(:skill) }
    let(:skill2) { FactoryGirl.create(:skill) }

    before(:each) do
      skill1
      skill2
      visit new_employee_path

      fill_in "employee[name]", with: "John Smith"
      fill_in "employee[email]", with: "john.smith@gmail.com"
      add_select2 "Skills", with: skill1.to_label
    end

    it "adds skill" do
      click_on "Save"
      
      created_employee = Employee.last
      expect(created_employee.skill_ids).to include(skill1.id) 
    end

    it "adds skills" do
      add_select2 "Skills", with: skill2.to_label
      click_on "Save"
      
      created_employee = Employee.last
      expect(created_employee.skill_ids).to eq [skill1.id, skill2.id]
    end

    it "removes skill" do
      # remove_all_select2 "Skills"
      remove_select2 "Skills", with: skill1.to_label

      click_on "Save"
      
      created_employee = Employee.last
      expect(created_employee.skill_ids).to be_empty
    end
  end



  describe "create with invalid object" do
    before(:each) do
      visit new_employee_path
      fill_in "employee[name]", with: "Paul Dot"
      click_on "Save"
      # post new_employee_path(:employee => {:id => 1})
    end

    it "shows an error message" do
      expect(page).to have_content("Some errors were found, please take a look:")
    end
  end

  describe "create with uniqueness constraint violated", :given => "a employee exists" do
    before(:each) do
      employee = FactoryGirl.create :employee
      visit new_employee_path
      fill_in "employee[name]", with: "Paul Dot"
      fill_in "employee[email]", with: "#{employee.email}"
      click_on "Save"

      # post new_employee_path(:employee => {:name => "Paul Dot", :email => employee.email })
    end

    it "shows an error message" do
      expect(page).to have_content("Some errors were found, please take a look:")
      expect(page).to have_content("must be unique")
    end
  end

  describe "authentication" do
    let(:ability) { Object.new.extend(CanCan::Ability) }

    it "does not allow to create new record" do
      ability.cannot :create, Employee
      ApplicationController.any_instance.stub(:current_ability).and_return(ability)
      expect {
        page.driver.submit :post, "/employees", { employee: { name: "created employee", email: "foo@bar.com"} }
      }.to_not change(Employee, :count).by(1)
      expect(page.driver.status_code).to_not eq 200
    end
  end

  describe "create object with errors on base" do
    before(:each) do
      visit new_employee_path
      fill_in "employee[name]", :with => "John Smith"
      fill_in "employee[email]", :with => "forbidden@mail.com"
      click_button "Save"
    end

    it "shows error base error message in flash" do
      expect(page).to have_content("This email is forbidden.")
    end
  end
end
