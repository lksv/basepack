require 'spec_helper'

describe "Basepack basic filter", type: :request, js: true do
  let(:employee1) { FactoryGirl.create :employee }
  let(:employee2) { FactoryGirl.create :employee }

  describe 'quick search' do
    before(:each) do
      employee1
      employee2

      visit employees_path
      click_on "Filter"
      sleep 0.7
    end

    it "finds by name" do
      fill_in "Filter", with: employee1.name
      sleep 0.2
      click_on "Refresh"

      expect(page).to have_css("tbody tr", :count => 1)
      expect(page).to have_content(employee1.name)
      expect(page).to_not have_content(employee2.name)
    end

    it "finds by email" do
      fill_in "Filter", with: employee2.email
      sleep 0.2
      click_on "Refresh"

      expect(page).to have_css("tbody tr", :count => 1)
      expect(page).to have_content(employee2.name)
      expect(page).to_not have_content(employee1.name)
    end

    it "finds by datetime" do
      employee1.update(created_at: Date.yesterday)
      fill_in "Filter", with: employee1.created_at
      sleep 0.2
      click_on "Refresh"

      expect(page).to have_css("tbody tr", :count => 1)
      expect(page).to have_content(employee1.name)
      expect(page).to_not have_content(employee2.name)
    end
  end

  # operators
  # 'eq'             => "=",
  # 'not_eq'         => "!=",
  # 'gteq'           => ">=",
  # 'lteq'           => "<=",
  # 'gt'             => ">",
  # 'lt'             => "<",
  # 'matches'        => "like",
  # 'does_not_match' => "not like",
  # 'cont'           => "cont",
  # 'not_cont'       => "not cont",
  # 'start'          => "start",
  # 'not_start'      => "not start",
  # 'end'            => "end",
  # 'not_end'        => "not end",
  # 'blank'          => "is blank",
  # 'present'        => "is not blank",
  # 'null'           => "is null",
  # 'not_null'       => "is not null",
  # 'true'           => "= true",
  # 'false'          => "= false",
  describe 'query by hand', js: true do

   before(:each) do
     ProjectsController.any_instance.stub(:default_list_section).and_return(:list)
     FactoryGirl.create(:project, name: "First project")
     FactoryGirl.create(:project, name: "Second project", description: "Description of second")
     FactoryGirl.create(:project, name: "Third", description:  "Description of third")
     visit projects_path
     click_on "Filter"
     sleep 0.8
     click_on "Modify query"
     sleep 1
   end

   it "query cont on attribute" do
     find(".input-xlarge").set "name cont 'project'"
     click_on "Refresh"
     # sleep 21

     expect(page).to have_css("tbody tr", count: 2)
     expect(page).to_not have_content("Third")
     expect(page).to have_content("First project")
     expect(page).to have_content("Second project")
   end

   it "query equal description" do
     find(".input-xlarge").set "description = 'Description of third'"
     click_on "Refresh"

     expect(page).to have_css("tbody tr", count: 1)
     expect(page).to_not have_content("First project")
     expect(page).to_not have_content("Second project")
     expect(page).to have_content("Third")
   end

   it "query not start and end attribute" do
     find(".input-xlarge").set "name not start 'Second' and name end 'project'"
     click_on "Refresh"

     expect(page).to have_css("tbody tr", count: 1)
     expect(page).to_not have_content("Third")
     expect(page).to_not have_content("Second project")
     expect(page).to have_content("First project")
   end

   it "query not cont and not equal attribute" do
     find(".input-xlarge").set "name cont 'project' and name != 'First project'"
     click_on "Refresh"

     expect(page).to have_css("tbody tr", count: 1)
     expect(page).to_not have_content("First project")
     expect(page).to_not have_content("Third")
     expect(page).to have_content("Second project")
   end
  end

  describe 'query by hand with associations', js: true do
    before(:each) do
      ProjectsController.any_instance.stub(:default_list_section).and_return(:list)
      employee1
      employee2
      FactoryGirl.create(:project, name: "First project", employee_id: employee1.id)
      FactoryGirl.create(:project, name: "Second project", description: "Description of second", employee_id: employee1.id)
      FactoryGirl.create(:project, name: "Third", description:  "Description of third", employee_id: employee2.id)
      visit projects_path
      click_on "Filter"
      sleep 0.6
      click_on "Modify query"
      sleep 0.7
    end

    it "query association attributes equal" do
      find(".input-xlarge").set "employee_name = '#{employee1.name}'"
      click_on "Refresh"

      expect(page).to have_css("tbody tr", count: 2)
      expect(page).to_not have_content("Third")
      expect(page).to have_content("First project")
      expect(page).to have_content("Second project")
    end

    it "query association attributes not equal" do
      find(".input-xlarge").set "employee_email != '#{employee1.email}'"
      click_on "Refresh"

      expect(page).to have_css("tbody tr", count: 1)
      expect(page).to_not have_content("First project")
      expect(page).to_not have_content("Second project")
      expect(page).to have_content("Third")
    end
  end

  describe 'query by clicking', js: true do
    before(:each) do
      FactoryGirl.create(:project, name: "First project", deadline: Date.today.beginning_of_month)
      FactoryGirl.create(:project, name: "Second project", description: "Description of second")
      FactoryGirl.create(:project, name: "Third", description:  "Description of third")
      visit projects_path
      click_on "Filter"
      sleep 0.8
      click_on "Add Filter"
    end

    it "shows datepicker and query by deadline" do
      pending "need to be fixed"
      click_on "Add Filter"

      within(".dropdown-menu") do
        click_on "Deadline"
      end
      find(".additional-fieldset").click
      find('.hasDatepicker').click
      within("#ui-datepicker-div") do
        click_on "1"
      end

      click_on "Refresh"

      expect(page).to have_css("tbody tr", count: 1)
      expect(page).to_not have_content("Third")
      expect(page).to_not have_content("Second project")
      expect(page).to have_content("First project")
    end

    it "query cont on attribute" do
      pending "do not work on TravisCI"
      # page.save_screenshot 'page.jpg', full: true
      within(".dropdown-menu") do
        click_on "Name"
      end
      find(".additional-fieldset").set('project')
      click_on "Refresh"

      expect(page).to have_css("tbody tr", count: 2)
      expect(page).to_not have_content("Third")
      expect(page).to have_content("First project")
      expect(page).to have_content("Second project")
    end
  end
end
