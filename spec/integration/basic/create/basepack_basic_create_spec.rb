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

  # describe "create with belongs_to association", js: true do
  #   before(:each) do
  #     @position = FactoryGirl.create :position, name: "My position"
  #     visit new_employee_path
  #     fill_in "employee[name]", with: "John Smith"
  #     fill_in "employee[email]", with: "john.smith@gmail.com"
  #     select 'My position', from: Position
  #     sleep 15
  #     click_on "Save"


  #     # post new_employee_path(:employee => {
  #     #   :name => "John Smith", 
  #     #   :email => "john.smith@gmail.com", 
  #     #   :income => 1500, 
  #     #   :position_id => @position.id
  #     #   }
  #     # )

  #     @created_employee = Employee.last
  #   end

  #   it "creates an object with correct associations" do
  #     @position.reload
  #     expect(@created_employee.position).to eq(@position)
  #   end
  # end

  # describe "create with has-many association" do
  #   before(:each) do
  #     @divisions = 3.times.map { Division.create!(:name => "div #{Time.now.to_f}", :league => League.create!(:name => "league #{Time.now.to_f}")) }
  #     post new_path(:model_name => "league", :league => {:name => "National League", :division_ids =>[@divisions[0].id]})
  #     @league = RailsAdmin::AbstractModel.new("League").all.to_a.last
  #   end

  #   it "creates an object with correct associations" do
  #     @divisions[0].reload
  #     expect(@league.divisions).to include(@divisions[0])
  #     expect(@league.divisions).not_to include(@divisions[1])
  #     expect(@league.divisions).not_to include(@divisions[2])
  #   end
  # end

  # describe "create with has-and-belongs-to-many association" do
  #   before(:each) do
  #     @teams = 3.times.map { FactoryGirl.create :team }
  #     post new_path(:model_name => "fan", :fan => {:name => "John Doe", :team_ids => [@teams[0].id] })
  #     @fan = RailsAdmin::AbstractModel.new("Fan").first
  #   end

  #   it "creates an object with correct associations" do
  #     @teams[0].reload
  #     expect(@fan.teams).to include(@teams[0])
  #     expect(@fan.teams).not_to include(@teams[1])
  #     expect(@fan.teams).not_to include(@teams[2])
  #   end
  # end

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

  describe "create with object with errors on base" do
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
