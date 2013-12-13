require 'spec_helper'

describe "Lepidlo Basic Show" do
  # subject { page }
  let(:employee) { FactoryGirl.create :employee }
  let(:ability) { Object.new.extend(CanCan::Ability) }


  describe "responses" do
    it "success code with :html " do
      visit employee_path(id: employee.id)
      expect(page.driver.status_code).to eq 200 
    end

    it "raises NotFound" do
      visit employee_path(id: '123this-id-doesnt-exist')
      expect(page.driver.status_code).to eq(404)
    end

    # not implemented yet
    # it "responses with :json" do
    #   pending "json"
    #   visit employee_path(:format => :json, :id => employee.id)

    #   expect(ActiveSupport::JSON.decode(page.body).length).to eq(1)
    #   ActiveSupport::JSON.decode(page.body).each do |employee|
    #     expect(employee).to have_key("id")
    #     expect(employee).to have_key("name")
    #     expect(employee).to have_key("email")
    #     expect(employee).to have_key("created_at")
    #     expect(employee).to have_key("updated_at")
    #   end
    # end

    # it "responses with :xml" do
    #   pending "add some examples to (or delete) #{__FILE__}"
    # end
  end

  describe "fields without association" do

    it "has Edit, Delete and attributes" do
      RailsAdmin.config Employee do
        show do
          include_all_fields
        end
      end
      visit employee_path(:id => employee.id)
      expect(page).to have_selector("a", :text => "Edit")
      expect(page).to have_selector("a", :text => "Delete")

      Employee.attribute_names.each do |attr|
        next if attr.in?(["id", "created_at", "updated_at"])
        expect(page).to have_content(Employee.human_attribute_name(attr))
        expect(page).to have_content(employee.send(attr))
      end
    end

    it "shows only defined columns" do
      RailsAdmin.config Employee do
        show do
          field :name
          field :income
        end
      end

      visit employee_path(:id => employee.id)

      expect(page).to have_content(employee.name)
      expect(page).to have_content(employee.income)

      expect(page).to have_no_content(employee.email)
    end

    it "properly format date columns" do
      RailsAdmin.config Employee do
        show do
          field :name
          field :created_at
        end
      end

      visit employee_path(:id => employee.id)

      expect(page).to have_content(I18n.l employee.created_at, format: :long)
    end

    describe "properly shows boolean field type" do
      before(:all) do
        RailsAdmin.config Employee do
          show do
            field :bonus
          end
        end
      end

      it "when true" do
        employee.update_attributes(bonus: true)
        visit employee_path(:id => employee.id)

        expect(page).to have_content("Bonus")
        within('.badge') do
          expect(page).to have_content("✓")
        end
      end

      it "when false" do
        employee.update_attributes(bonus: false)
        visit employee_path(:id => employee.id)

        within('.badge') do
          expect(page).to have_content("✘")
        end
      end

      it "when nil" do
        employee.update_attributes(bonus: nil)
        visit employee_path(:id => employee.id)
        within('.badge') do
          expect(page).to have_content("-")
        end
      end

    end
  end

  describe "belongs_to association" do
    before(:each) do
      RailsAdmin.config Employee do
        show do
          field :position
        end
      end

      employee.position = FactoryGirl.create(:position, name: "My Position")
      employee.save!
    end

    context "when has access" do
      it "it shows as link" do
        visit employee_path(:id => employee.id)

        click_on "My Position"
        expect(current_path).to eq position_path(employee.position)
      end
    end

    context "when has no access" do
      it "it shows as text" do
        ability.can :manage, :all
        ability.cannot :show, Position
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)

        visit employee_path(:id => employee.id)
        expect(page).to have_content('My Position')
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
      employee.account = FactoryGirl.create(:account)
      employee.save!
    end

    context "when has access" do
      it "shows as link" do
        visit employee_path(id: employee.id)

        click_on "Account #{employee.account.account_number}"
        expect(current_path).to eq account_path(employee.account)
      end
    end

    context "when has no access" do
      it "shows as text" do
        ability.can :manage, :all
        ability.cannot :show, Account
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)
        visit employee_path(id: employee.id)

        expect(page).to have_content("Account #{employee.account.account_number}")
        expect(page).to_not have_selector(:link_or_button, "Account #{employee.account.account_number}")
      end
    end
  end

  describe "has_many association" do
    before(:each) do
      @task1 = FactoryGirl.create :task, :employee_id => employee.id, description: "first task"
      @task2 = FactoryGirl.create :task, :employee_id => employee.id, description: "second task"

      RailsAdmin.config Employee do
        field :tasks
      end
    end

    context "when has access" do
      it "shows as links" do
        visit employee_path(:id => employee.id)
        expect(page).to have_content('first task and second task')
        expect(page).to have_selector(:link_or_button, 'first task')
        expect(page).to have_selector(:link_or_button, 'second task')
        click_on "first task"
        expect(current_path).to eq task_path(employee.tasks.first)
      end
    end

    context "when has no access" do
      it "shows as text" do
        ability.can :manage, :all
        ability.cannot :show, Task
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)
        visit employee_path(:id => employee.id)

        expect(page).to have_content('first task and second task')
        expect(page).to_not have_selector(:link_or_button, 'first task')
        expect(page).to_not have_selector(:link_or_button, 'second task')
      end
    end
  end

  describe "has_and_belongs_to_many association" do
    before(:each) do
      employee.skills = 2.times.map { |n| FactoryGirl.create(:skill, name: "skill #{n + 1}") }
      employee.save!
      RailsAdmin.config Employee do
        field :skills
      end
    end

    context "when has access" do
      it "shows as links" do
        visit employee_path(:id => employee.id)
        expect(page).to have_content('skill 1 and skill 2')
        expect(page).to have_selector(:link_or_button, 'skill 1')
        expect(page).to have_selector(:link_or_button, 'skill 2')

        click_on "skill 1"
        expect(current_path).to eq skill_path(employee.skills.first)
      end
    end

    context "when has no access" do
      it "shows as text" do
        ability.can :manage, :all
        ability.cannot :show, Skill
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)
        visit employee_path(:id => employee.id)

        expect(page).to have_content('skill 1 and skill 2')
        expect(page).to_not have_selector(:link_or_button, 'skill 1')
        expect(page).to_not have_selector(:link_or_button, 'skill 2')
      end
    end
  end

=begin
  describe "show for polymorphic objects" do
    beforere(:each) do
      employee = FactoryGirl.create :employee
      @comment = FactoryGirl.create :comment, :commentable => employee
      visit employee_path(:model_name => "comment", :id => @comment.id)
    end

    it "shows associated object" do
      should have_css("a[href='/admin/employee/#{employee.id}']")
    end
  end
=end
end
