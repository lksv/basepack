require 'spec_helper'

describe "Basepack basic list", type: :request do
  # subject { page }

  let(:employee1) { FactoryGirl.create :employee }
  let(:employee2) { FactoryGirl.create :employee }

  let(:employees) { [employee1, employee2] }

  let(:ability) { Object.new.extend(CanCan::Ability) }

  describe "responses" do

    it "success code with :html", js: true do
      employees
      visit employees_path
      expect(page.driver.status_code).to eq 200
    end

    it "responses with :json" do
      # touch employees to create them
      employees
      visit employees_path(:format => :json)
      expect(ActiveSupport::JSON.decode(page.body).length).to eq(2)
      ActiveSupport::JSON.decode(page.body).each do |employee|
        expect(employee).to have_key("id")
        expect(employee).to have_key("name")
        expect(employee).to have_key("email")
        expect(employee).to have_key("created_at")
        expect(employee).to have_key("updated_at")
      end
    end

    it "responses with :xml" do
      employees
      visit employees_path(:format => :xml)
      xml = Nokogiri::XML(page.html)
      expect(xml.xpath("//employee").count).to eq(2)

      xml.xpath("//employee").each do |employee|
        expect(employee.xpath('id')).to_not be_empty
        expect(employee.xpath('name')).to_not be_empty
        expect(employee.xpath('email')).to_not be_empty
        expect(employee.xpath('created-at')).to_not be_empty
        expect(employee.xpath('updated-at')).to_not be_empty
      end

    end

    context "unauthorized" do
      it "rejects list" do
        ability.can :manage, :all
        ability.cannot :index, Employee
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)
        visit employees_path
        expect(page.driver.status_code).not_to eq 200
      end
    end

  end

  describe "actions" do
    context "authorized" do
      it "has Show, Add new, Edit and Delete links" do
        employee1
        visit employees_path

        expect(page.driver.status_code).to eq 200
        expect(page).to have_selector(:link_or_button, "Show")
        expect(page).to have_selector(:link_or_button, "Edit")
        expect(page).to have_selector(:link_or_button, "Add new")
        expect(page).to have_selector(:link_or_button, "Delete")
      end

      it "displays show page" do
        employee1
        visit employees_path
        click_on "Show"
        expect(current_path).to eq employee_path(id: employee1.id)
      end

      it "displays edit page" do
        employee1
        visit employees_path
        click_on "Edit"
        expect(current_path).to eq edit_employee_path(id: employee1.id)
      end

      it "displays new page" do
        visit employees_path
        click_on "Add new"
        expect(current_path).to eq new_employee_path
      end

      it "deletes an employee" do
        employees
        visit employees_path

        within("tbody tr:first") do
          click_on "Delete"
        end

        expect(page).to_not have_content(employees[0].name)
        expect(page).to have_content(employees[1].name)
        expect(page).to have_css("tbody tr", :count => 1)
      end
    end

    context "unauthorized" do
      before(:each) do
        ability.can :manage, :all
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)
      end

      it "without Show link and access" do
        ability.cannot :show, Employee

        employee1
        visit employees_path
        expect(page).to have_no_selector(:link_or_button, "Show")

        visit employee_path(employee1)
        expect(page.driver.status_code).to_not eq 200
      end

      it "without Edit link and access" do
        ability.cannot :edit, Employee

        employee1
        visit employees_path
        expect(page).to have_no_selector(:link_or_button, "Edit")

        visit edit_employee_path(employee1)
        expect(page.driver.status_code).to_not eq 200
      end

      it "without Add new link and access" do
        ability.cannot :create, Employee

        visit employees_path
        expect(page).to have_no_selector(:link_or_button, "Add new")

        visit new_employee_path
        expect(page.driver.status_code).to_not eq 200
      end

      it "without Delete link and permission" do
        ability.cannot :destroy, Employee

        employee1
        visit employees_path
        expect(page).to have_no_selector(:link_or_button, /\ADelete\Z/)

        page.driver.submit :delete, "/employees/#{employee1.id}", {}
        expect(page.driver.status_code).to_not eq 200

        visit employees_path
        expect(page).to have_css("tbody tr", :count => 1)
      end
    end

  end

  describe "fields without association" do

    it "shows all fields as default" do
      visit employees_path
      Employee.attribute_names.each do |attr|
        expect(page).to have_content(Employee.human_attribute_name(attr))
      end
    end

    it "shows only defined columns" do
      RailsAdmin.config Employee do
        list do
          field :name
        end
      end
      employees
      visit employees_path()

      expect(page).to have_content(employees[0].name)
      expect(page).to have_content(employees[1].name)
      expect(page).to have_no_content(employees[0].email)
      expect(page).to have_no_content(employees[1].email)
    end

    it "properly format date columns" do
      RailsAdmin.config Employee do
        list do
          field :name
          field :created_at
        end
      end
      employee1

      visit employees_path()
      expect(page).to have_content(I18n.l employee1.created_at, format: :long)
    end

    describe "properly shows boolean field type" do
      before(:all) do
        RailsAdmin.config Employee do
          list do
            field :bonus
          end
        end
      end

      it "when true" do
        employee1.update_attributes(bonus: true)
        visit employees_path()
        expect(page).to have_content("Bonus")
        expect(page).to have_content("✓")

      end

      it "when false" do
        employee1.update_attributes(bonus: false)
        visit employees_path()
        expect(page).to have_content("Bonus")
        expect(page).to have_content("✘")
      end

      it "when nil" do
        employee1.update_attributes(bonus: nil)
        visit employees_path()
        expect(page).to have_content("Bonus")
        expect(page).to have_content("-")
      end
    end
  end

  describe "belongs_to association" do
    before(:each) do
      RailsAdmin.config Employee do
        list do
          field :position
        end
      end
      employee1.position = FactoryGirl.create(:position, name: 'My Position')
      employee1.save!
    end

    context "when has access" do
      it "shows as link" do
        visit employees_path

        click_on "My Position"
        expect(current_path).to eq position_path(employee1.position)
      end
    end

    context "when has no access" do
      it "shows as text" do
        ability.can :manage, :all
        ability.cannot :show, Position
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)

        visit employees_path
        expect(page).to have_content("My Position")
        expect(page).to_not have_selector(:link_or_button, 'My Position')
      end
    end
  end

  describe "has_one association" do
    before(:each) do
      RailsAdmin.config Employee do
        list do
          field :account
        end
      end
      employee1.account = FactoryGirl.create(:account)
      employee1.save!
    end

    context "when has access" do
      it "shows as link" do
        visit employees_path

        click_on "Account #{employee1.account.account_number}"
        expect(current_path).to eq account_path(employee1.account)
      end
    end

    context "when has no access" do
      it "shows as text" do
        ability.can :manage, :all
        ability.cannot :show, Account
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)
        visit employees_path

        expect(page).to have_content("Account #{employee1.account.account_number}")
        expect(page).to_not have_selector(:link_or_button, "Account #{employee1.account.account_number}")
      end
    end
  end

  describe "has_many association" do
    before(:each) do
      RailsAdmin.config Employee do
        list do
          field :projects
        end
      end

      employee1.projects.build(name: 'first project')
      employee1.projects.build(name: 'second project')
      employee1.save!
    end

    context "when has access" do
      it "shows as links" do
        visit employees_path
        expect(page).to have_content('first project and second project')
        expect(page).to have_selector(:link_or_button, 'first project')
        expect(page).to have_selector(:link_or_button, 'second project')
        click_on "first project"
        expect(current_path).to eq project_path(employee1.projects.first)
      end
    end

    context "when has no access" do
      it "shows only text" do
        ability.can :manage, :all
        ability.cannot :show, Project
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)

        visit employees_path
        expect(page).to have_content('first project and second project')
        expect(page).to_not have_selector(:link_or_button, 'first project')
        expect(page).to_not have_selector(:link_or_button, 'second project')
      end
    end
  end


  describe "has_many through association" do
    before(:each) do
      RailsAdmin.config Employee do
        list do
          field :tasks
        end
      end
      task1 = FactoryGirl.build(:task, description: 'first task')
      task2 = FactoryGirl.build(:task, description: 'second task')
      project1 = FactoryGirl.build(:project, tasks: [task1, task2])
      employee1.projects << project1
      employee1.save!
    end

    context "when has access" do
      it "shows as links" do
        visit employees_path
        expect(page).to have_content('first task and second task')
        expect(page).to have_selector(:link_or_button, 'first task')
        expect(page).to have_selector(:link_or_button, 'second task')
        click_on "first task"
        expect(current_path).to eq task_path(employee1.tasks.first)
      end
    end

    context "when has no access" do
      it "shows only text" do
        ability.can :manage, :all
        ability.cannot :show, Task
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)

        visit employees_path
        expect(page).to have_content('first task and second task')
        expect(page).to_not have_selector(:link_or_button, 'first task')
        expect(page).to_not have_selector(:link_or_button, 'second task')
      end
    end

  end

  describe "has_and_belongs_to_many association" do
    before(:each) do
      RailsAdmin.config Employee do
        list do
          field :skills
        end
      end
      employee1.skills = 2.times.map { |n| FactoryGirl.create(:skill, name: "skill #{n + 1}") }
      employee1.save!
    end

    context "when has access" do
      it "shows as links" do
        visit employees_path
        expect(page).to have_content('skill 1 and skill 2')
        expect(page).to have_selector(:link_or_button, 'skill 1')
        expect(page).to have_selector(:link_or_button, 'skill 2')
        click_on "skill 1"
        expect(current_path).to eq skill_path(employee1.skills.first)
      end
    end

    context "when has no access" do
      it "shows only text" do
        ability.can :manage, :all
        ability.cannot :show, Skill
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)

        visit employees_path

        expect(page).to have_content('skill 1 and skill 2')
        expect(page).to_not have_selector(:link_or_button, 'skill 1')
        expect(page).to_not have_selector(:link_or_button, 'skill 2')
      end
    end

  end

  describe "pagination" do
    before do
      #FIXME: setting RailsAdmin items_pare_page do not work for me:( decrease the creating objects to 5.
      # TODO does items_per_page work? in issue_tracking app it does not
      53.times { FactoryGirl.create(:employee) }
      RailsAdmin.config.default_items_per_page = 1
      RailsAdmin.config Employee do
        list do
          items_per_page 1
        end
      end
      visit employees_path(:page => 2)
    end

    it "shows total number of items" do
      # save_and_open_page
      expect(page).to have_content('53 in total')
    end

    it "paginates correctly" do
      expect(find('.pagination ul li:first')).to have_content("« First")
      expect(find('.pagination ul li:nth(2)')).to have_content("‹ Prev")
      expect(find('.pagination ul li:nth-last-child(2)')).to have_content("Next ›")
      expect(find('.pagination ul li:last')).to have_content("Last »")
      expect(find('.pagination ul li.active')).to have_content("2")
    end
  end

  describe "sorting" do
    let!(:employee1) { FactoryGirl.create(:employee, name: 'xxx') }
    let!(:employee2) { FactoryGirl.create(:employee, name: 'yyy') }
    let!(:employee3) { FactoryGirl.create(:employee, name: 'xxxx') }

    before(:each) do
      RailsAdmin.config Employee do
        list do
          field :name
          field :created_at
        end
      end
    end

    it "sorts by name asceding" do
      visit employees_path('f[s]' => 'name asc')
      expect(page).to have_selector("tbody tr:first", text: "xxx")
      expect(page).to have_selector("tbody tr:nth(2)", text: "xxxx")
      expect(page).to have_selector("tbody tr:nth(3)", text: "yyy")
    end

    it "sorts by name descending" do
      visit employees_path('f[s]' => 'name desc')
      expect(page).to have_selector("tbody tr:first", text: "yyy")
      expect(page).to have_selector("tbody tr:nth(2)", text: "xxxx")
      expect(page).to have_selector("tbody tr:nth(3)", text: "xxx")
    end

    it "sorts by date asceding" do
      visit employees_path
      click_on 'Created at'
      expect(page).to have_selector("tbody tr:first", text: (I18n.l employee1.created_at, format: :long))
      expect(page).to have_selector("tbody tr:nth(2)", text: (I18n.l employee2.created_at, format: :long))
      expect(page).to have_selector("tbody tr:nth(3)", text: (I18n.l employee3.created_at, format: :long))
    end

    it "sorts by date descending" do
      visit employees_path
      click_on 'Created at'
      click_on 'Created at'
      expect(page).to have_selector("tbody tr:first", text: (I18n.l employee3.created_at, format: :long))
      expect(page).to have_selector("tbody tr:nth(2)", text: (I18n.l employee2.created_at, format: :long))
      expect(page).to have_selector("tbody tr:nth(3)", text: (I18n.l employee1.created_at, format: :long))
    end
  end

  describe "sorting combined fields" do
    let!(:employee1) { FactoryGirl.create(:employee, name: 'xxx', title: "Mrs") }
    let!(:employee2) { FactoryGirl.create(:employee, name: 'yyy', title: "Mr") }
    let!(:employee3) { FactoryGirl.create(:employee, name: 'xxx', title: "Miss.") }

    before(:each) do
      RailsAdmin.config Employee do
        list do
          field :name_with_title do
            label 'Title and name'
            sortable [:name, :title]
          end
        end
      end
      # touch all employees
      employee1
      employee2
      employee3
      visit employees_path
    end

    it "sorts title and name asceding" do
      click_on "Title and name"
      expect(page).to have_selector("tbody tr:first", text: employee3.name_with_title)
      expect(page).to have_selector("tbody tr:nth(2)", text: employee1.name_with_title)
      expect(page).to have_selector("tbody tr:nth(3)", text: employee2.name_with_title)
    end

    it "sorts title and name descending" do
      click_on "Title and name"
      click_on "Title and name"
      expect(page).to have_selector("tbody tr:first", text: employee2.name_with_title)
      expect(page).to have_selector("tbody tr:nth(2)", text: employee1.name_with_title)
      expect(page).to have_selector("tbody tr:nth(3)", text: employee3.name_with_title)
    end
  end

  describe "filter params" do
    let!(:employee1) { FactoryGirl.create(:employee, name: 'xxx') }
    let!(:employee2) { FactoryGirl.create(:employee, name: 'yyy') }
    let!(:employee3) { FactoryGirl.create(:employee, name: 'xxxx') }

    describe "default filter" do
      before(:each) do
        EmployeesController.any_instance.stub(:default_query_params).and_return(
          { "f[name_eq]" => "xxx" }
        )
      end

      it "uses default filter when no search params provided" do
        visit employees_path
        expect(page).to have_content(employee1.name)
        expect(page).to have_no_content(employee2.name)
        expect(page).to have_css("tbody tr", :count => 1)
      end

      it "do not use default filter when search params provided" do
        visit employees_path('f[name_not_eq]' => '123')

        expect(page).to have_content(employee1.name)
        expect(page).to have_content(employee2.name)
        expect(page).to have_content(employee3.name)
      end
    end

    it "correctly filters contains" do
      visit employees_path('f[name_cont]' => 'xxx')

      expect(page).to have_css("tbody tr", :count => 2)
      expect(page).to have_content(employee1.name)
      expect(page).to_not have_content(employee2.name)
      expect(page).to have_content(employee3.name)
    end
  end
end
