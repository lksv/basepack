require 'spec_helper'
include Warden::Test::Helpers
include Devise::TestHelpers

describe "Lepidlo basic list" do
  subject { page }

  describe "GET /employees" do

    before(:each) do
      @employees = 2.times.map { FactoryGirl.create :employee }
    end

    it "has Show, Edit and Delete links" do
      visit employees_path
      expect(page).to have_selector(:link_or_button, "Show")
      expect(page).to have_selector(:link_or_button, "Edit")
      expect(page).to have_selector(:link_or_button, "Delete")
    end

    it "shows all fields when as default" do
      visit employees_path
      Employee.attribute_names.each do |attr|
        expect(page).to have_content(Employee.human_attribute_name(attr))
      end
    end

    it "show only defined columns" do
      RailsAdmin.config Employee do
        list do
          field :name
        end
      end

      visit employees_path()

      expect(page).to have_content(@employees[0].name)
      expect(page).to have_content(@employees[1].name)
      expect(page).to have_no_content(@employees[0].email)
      expect(page).to have_no_content(@employees[1].email)
    end

    it "properly format date columns" do
      RailsAdmin.config Employee do
        list do
          field :name
          field :created_at
        end
      end

      visit employees_path()
      expect(page).to have_content(I18n.l @employees.first.created_at, format: :long)
    end

    it "properly shows boolean field type" do
      @employees.first.update_attributes(bonus: true)

      RailsAdmin.config Employee do
        list do
          field :bonus
        end
      end
      visit employees_path()

      expect(page).to have_content("Bonus")
      expect(page).to have_content("✓")
    end

    it "respons with :json" do
      visit employees_path(:format => :json)
      expect(ActiveSupport::JSON.decode(page.body).length).to eq(2)
      ActiveSupport::JSON.decode(page.body).each do |object|
        expect(object).to have_key("id")
        expect(object).to have_key("name")
        expect(object).to have_key("email")
        expect(object).to have_key("created_at")
        expect(object).to have_key("updated_at")
      end
    end

    it "respons with :xml" do
      pending "add some examples to (or delete) #{__FILE__}"
    end

    describe "belongs_to association" do
      before(:each) do
        RailsAdmin.config Employee do
          list do
            field :position
          end
        end
        @employees.first.position = FactoryGirl.create(:position, name: 'My Position')
        @employees.first.save!

      end

      context "when has access" do
        it "shows as link" do
          visit employees_path

          expect(page).to have_selector(:link_or_button, 'My Position')
        end
      end

      context "when has no access" do
        it "shows as text" do
          @ability = Object.new
          @ability.extend(CanCan::Ability)
          @ability.can :manage, :all
          @ability.cannot :show, Position
          ApplicationController.any_instance.stub(:current_ability).and_return(@ability)

          visit employees_path
          expect(page).to have_content("My Position")
          expect(page).to_not have_selector(:link_or_button, 'My Position')
        end
      end
    end

    describe "has_many association" do
      before do
        RailsAdmin.config Employee do
          list do
            field :tasks
          end
        end
        employee = @employees.first
        employee.tasks.build(description: 'first task')
        employee.tasks.build(description: 'second task')
        employee.save!
      end

      context "when has access" do
        it "shows as links" do
          visit employees_path
          expect(page).to have_content('first task and second task')
          expect(page).to have_selector(:link_or_button, 'first task')
          expect(page).to have_selector(:link_or_button, 'second task')
        end
      end

      context "when has no access" do
        it "show only text" do
          @ability = Object.new
          @ability.extend(CanCan::Ability)
          @ability.can :manage, :all
          @ability.cannot :show, Task
          ApplicationController.any_instance.stub(:current_ability).and_return(@ability)

          visit employees_path
          expect(page).to have_content('first task and second task')
          expect(page).to_not have_selector(:link_or_button, 'first task')
          expect(page).to_not have_selector(:link_or_button, 'second task')
        end
      end

    end

    describe "pagination" do
      before do
        #FIXME: setting RailsAdmin items_pare_page do not work for me:( decrease the creating objects to 5.
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
        expect(page).to have_content('55 in total')
      end

      it "paginates correctly" do
        expect(find('.pagination ul li:first')).to have_content("« First")
        expect(find('.pagination ul li:nth(2)')).to have_content("‹ Prev")
        expect(find('.pagination ul li:nth-last-child(2)')).to have_content("Next ›")
        expect(find('.pagination ul li:last')).to have_content("Last »")
        expect(find('.pagination ul li.active')).to have_content("2")
      end

    end

    describe "filters" do
      before do
        @c1 = FactoryGirl.create(:employee, name: 'xxx')
        @c2 = FactoryGirl.create(:employee, name: 'yyy')
        @c3 = FactoryGirl.create(:employee, name: 'xxxx')
      end

      describe "default filter" do
        before do
          EmployeesController.default_query do
            { "f[name_eq]" => "xxx" }
          end
        end

        it "uses default filter when no search params provided" do
          visit employees_path

          expect(page).to have_content(@c1.name)
          expect(page).to have_no_content(@c2.name)
          expect(page).to have_css("tbody tr", :count => 1)
        end

        it "do not use default filter when search params provided" do
          visit employees_path('f[name_not_eq]' => '123')

          expect(page).to have_content(@c1.name)
          expect(page).to have_content(@c2.name)
          expect(page).to have_content(@c3.name)
        end
      end

    end

    #TODO what to test:
    # show only if ability is provided
    # filter:
    #   filter by belongs_to
    #   filter by has_many
    #   filter by boolean
    #   filter by date
    #   filter by _contains
    #   filter by _eq
    # sorting:
    #   ....
    #
    #pagination (max row per page)
    #pagination - info about max items
  end

end
