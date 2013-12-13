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
      expect(page).to have_content("Employee / New")
    end

    it "shows required fields as \"Required\"" do
      expect(page).to have_selector("div", :text => /Name\s*Required/)
      expect(page).to have_selector("div", :text => /Email\s*Required/)
    end

    it "shows non-required fields as \"Optional\"" do
      expect(page).to have_selector(".employee_income .hint", :text => "Optional")
    end
  end

  describe "GET /employees/new with has-one/belongs_to/has_many through/habtm association" do
    before(:each) do
      employee = FactoryGirl.create :employee  #TODO FactoryGirl.create :empoyee_with_all_associations
      employee.account = FactoryGirl.build :account
      employee.position = FactoryGirl.build :position
      tasks = 2.times.map { FactoryGirl.build :task }
      employee.projects << FactoryGirl.build(:project, tasks: tasks)
      employee.skills = 2.times.map { FactoryGirl.build :skill }
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
      # js: true
      # sleep 100
      # TODO
      pending "has_one Account not displayed"
      expect(page).to have_selector("select#employee_account")
      expect(page).to have_selector("select#employee_position")
      expect(page).to have_selector("select#employee_tasks")
      expect(page).to have_selector("select#employee_skills")
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

    it "prepropulates belongs to relationships", js: true do
      RailsAdmin.config Employee do
        field :name
        field :position
      end

      position = FactoryGirl.create(:position)

      visit new_employee_path(:employee => { position_id: position.id } )

      expect(page).to have_select2('Position', selected: position.to_label)
    end

    #it "prepropulates has_many relationships", js: true do
    #  RailsAdmin.config Employee do
    #    field :name
    #    field :tasks
    #  end

    #  employee = FactoryGirl.build :employee, :name => "has_many association prepopulated"
    #  employee.tasks = 2.times.map { FactoryGirl.build :task }
    #  employee.save!

    #  visit new_employee_path(:employee => { :task_ids => employee.task_ids } )

    #  expect(page).to have_select2( 'Tasks', selected: employee.tasks[0].to_label )
    #  expect(page).to have_select2( 'Tasks', selected: employee.tasks[1].to_label )
    #end
  end
end
