require 'spec_helper'

describe "Lepidlo Basic Show" do
  describe "GET /employees/new without association" do
    before(:each) do
      RailsAdmin.config Employee do
        field :name
        field :email
        field :bonus
        field :income
      end

      visit new_employee_path
    end

    it "shows \"New Model\"" do
      # TODO without styling
      expect(page).to have_content("Employee / New")
    end

    it "shows required fields as \"Required\"" do
      expect(page).to have_selector("div", :text => /Name\s*Required/)
      expect(page).to have_selector("div", :text => /Email\s*Required/)
    end

    it "shows non-required fields as \"Optional\"" do
      # TODO rails_admin has it as id not class
      # expect(page).to have_selector(".employee_income .help-block", :text => "Optional")
      expect(page).to have_selector(".employee_income .hint", :text => "Optional")
    end
  end

  describe "GET /employees/new with has-one/belongs_to/has_many/habtm association" do
    before(:each) do
      employee = FactoryGirl.create :employee
      employee.account = FactoryGirl.create :account
      employee.position = FactoryGirl.create :position
      employee.tasks = 2.times.map { FactoryGirl.create :task }
      employee.skills = 2.times.map { FactoryGirl.create :skill }
      employee.save!
      
      RailsAdmin.config Employee do
        field :account
        field :position
        field :tasks
        field :skills
      end

      visit new_employee_path
    end

    it "shows selects" do
      pending "select box is missing"
      save_and_open_page
      expect(page).to have_selector("select#employee_account_id")
      expect(page).to have_selector("select#employee_position_id")
      expect(page).to have_selector("select#employee_tasks_ids")
      expect(page).to have_selector("select#employee_skills_ids")
    end
  end

  describe "GET /employees/new with parameters for pre-population" do
    it "populates form field when corresponding parameters are passed in" do
      RailsAdmin.config Employee do
        field :name
      end
      visit new_employee_path(:employee => {:name => 'Sam'})
      expect(page).to have_css('input[value=Sam]')
    end
    
=begin
    it "prepropulates belongs to relationships" do
      @position = FactoryGirl.create :position, :name => "belongs_to association prepopulated"
      visit new_employee_path(:associations => { :position => @position.id } )
      expect(page).to have_css("select#player_position_id option[selected='selected'][value='#{@position.id}']")
    end

    it "prepropulates has_many relationships" do
      @employee = FactoryGirl.create :employee, :name => "has_many association prepopulated"
      visit new_position_path(:associations => { :employees => @employee.id } )
      expect(page).to have_css("select#position_employee_ids option[selected='selected'][value='#{@employee.id}']")
    end
=end
  end
end