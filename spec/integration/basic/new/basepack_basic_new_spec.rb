require 'spec_helper'

describe "Basepack Basic New" do
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
    let!(:employee)  { FactoryGirl.create :employee_with_all_associations }

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

  describe "task dynamic attributes", js: true do
    before(:each) do
      RailsAdmin.config Task do
            edit do
              # field :status, :enum do
              field :name
              field :description

              field :status do
                visible true
                html_attributes do
                { 
                  data: { 
                    "dynamic-fields" => [
                      { condition: ["Postponed", "Done"], field_actions: { completed_percents: { visible: false }} },
                      { condition: ["In progress"], field_actions: { completed_percents: { visible: true  }} },
                    ]   
                  }   
                }   
                end
              end

              field :completed_percents
          end
      end
    end

    it "hides field", js:true do
      pending "basepack helper"
      visit new_task_path
      # save_and_open_page
      fill_in "Status", with: "Postponed"
      fill_in "Name", with: "Test"
      # find("#employee_name").click      
      expect(page).to have_no_content('Completed percents')
    end

    it "shows field" do
      pending "basepack helper"
      visit new_task_path
      fill_in "Status", with: "In progress"
      fill_in "Name", with: "Test showing percents"
      expect(page).to have_content('Completed percents')
    end
  end

  describe "dependant select boxes", js: true do
    let!(:category_with_positions1) { FactoryGirl.create(:category_with_positions) }
    let!(:category_with_positions2) { FactoryGirl.create(:category_with_positions) }

    before(:each) do
      RailsAdmin.config Employee do
        field :position_category
        field :position do
          options_source_params do
            { "f[position_category_id_eq]" => bindings[:object].try(:project_category) || -1 }
          end

          html_attributes do
          { data: { 
            # set project's field as dependent select box
            "dependant-filteringselect" => "field=position_category_id",

            # post parameters
            "dependant-param" => "f[position_category_id_eq]" }
          }
          end
        end
      end
    end

    it "shows categories" do
      category_with_positions1
      category_with_positions2
      visit new_employee_path

      find("#s2id_employee_position_category_id .select2-chosen").click

      expect(page).to have_content(category_with_positions1.name)
      expect(page).to have_content(category_with_positions1.name)
    end

    it "selecting category limits positions" do
      pending "needs basepack helper"
    end

    it "shows no position when no category is choosen" do
      pending "needs basepack helper"
    end
  end

  describe "types", js: true do
    describe "wysihtml5" do
      before(:each) do
        RailsAdmin.config Project do 
          edit do
            field :description, :wysihtml5
            field :name
          end
        end
        visit new_project_path
      end

      it "displays wysihtml5 basic elements correctly" do
        expect(page).to have_selector(:link_or_button, "Normal text")
        expect(page).to have_selector(:link_or_button, "Bold")
        expect(page).to have_selector(:link_or_button, "Italic")
        expect(page).to have_selector(:link_or_button, "Underline")
      end

      it "tests editor", js: true do
        click_on "Bold"
        page.execute_script("editor.setValue('<b>This text is bold</b>')")
        expect(page).to have_no_content("<b>This text is bold</b>")

        click_on "Save"
        expect(page).to have_content("This text is bold")
      end
    end

    describe "datetime", js: true do
      it "displays date picker" do
        visit new_project_path
        find('.hasDatepicker').click
        within("#ui-datepicker-div") do
          click_on "1"
        end

        click_on "Save"
        sleep 100
        created_project = Project.last

        expect(page).to have_content(I18n.l created_project.deadline, format: :long)
        expect(Date.today.beginning_of_month).to eq created_project.deadline
      end

      it "displays time picker" do
        visit new_project_path
        find('.hasTimepicker').click
        page.execute_script %Q{ $('a.ui-datepicker-next').trigger("click") } # move one month forward 
        page.execute_script %Q{ $("a.ui-state-default:contains('15')").trigger("click") } # click on day 15

        click_on "Save"
        expect(page).to have_content("15:15")
      end
    end

    describe "tags", js: true do
      before(:each) do
        RailsAdmin.config Project do 
          show do
            field :tags
          end

          edit do
            field :name
            field :tag_list do
              partial 'tag_list_with_suggestions'
            end
          end
        end
      end

      it "shows fields and saves tags" do
        pending "helper needed"
        visit new_project_path
        expect(page).to have_selector(".icon-tags")
        # expect(page).to have_select2("Tag list")
      
        add_select2 "Tag list", with: "first tag, second"
        click_on "Save"

        expect(page).to have_content("first tag and second")
      end
    end
  end

  describe "authentication" do
    let(:ability) { Object.new.extend(CanCan::Ability) }

    it "does not show new page without access" do
      ability.cannot :new, Employee
      ApplicationController.any_instance.stub(:current_ability).and_return(ability)
      visit new_employee_path

      expect(page.driver.status_code).to_not eq 200

    end
  end
end
