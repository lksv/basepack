require 'spec_helper'

describe "Basepack Basic Show" do
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
      expect(page).to have_selector(".employee_income .help-block", text: "Optional")
    end
  end

  describe "GET /employees/new with has-one/belongs_to/has_many/has_many through/habtm association" do
    let!(:employee)  { FactoryGirl.create :empoyee_with_all_associations }

    before(:each) do
      RailsAdmin.config Employee do
        field :account
        field :position
        field :projects
        field :skills
      end

      visit new_employee_path(employee: employee.attributes.merge(
        account_id: employee.account_id,
        project_ids: employee.project_ids,
        skill_ids: employee.skill_ids
      ))
    end

    it "shows selects", js: true do
      expect(page).to have_select2("Account", selected: employee.account.to_label)
      expect(page).to have_select2("Position", selected: employee.position.to_label)
      expect(page).to have_select2("Projects", selected: employee.projects.first.to_label)
      expect(page).to have_select2("Projects", selected: employee.projects.last.to_label)
      expect(page).to have_select2("Skills", selected: employee.skills.first.to_label)
      expect(page).to have_select2("Skills", selected: employee.skills.last.to_label)
    end
  end

  describe "GET /employees/new with parameters for pre-population" do
    it "populates form field when corresponding parameters are passed in" do
      RailsAdmin.config Employee do
        field :name
      end
      visit new_employee_path(employee: {name: 'Sam'})
      expect(page).to have_css('input[value=Sam]')
    end

    it "prepropulates belongs to relationships", js: true do
      RailsAdmin.config Employee do
        field :name
        field :position
      end

      position = FactoryGirl.create(:position)

      visit new_employee_path(employee: { position_id: position.id } )

      expect(page).to have_select2('Position', selected: position.to_label)
    end

    #it "prepropulates has_many relationships", js: true do
    #  RailsAdmin.config Employee do
    #    field :name
    #    field :tasks
    #  end

    #  employee = FactoryGirl.build :employee, name: "has_many association prepopulated"
    #  employee.tasks = 2.times.map { FactoryGirl.build :task }
    #  employee.save!

    #  visit new_employee_path(employee: { task_ids: employee.task_ids } )

    #  expect(page).to have_select2( 'Tasks', selected: employee.tasks[0].to_label )
    #  expect(page).to have_select2( 'Tasks', selected: employee.tasks[1].to_label )
    #end
  end
end
