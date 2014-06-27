require 'spec_helper'

describe "Basepack Basic Edit", type: :request do
let!(:employee) { FactoryGirl.create(:employee) }

  describe "without association" do
    before(:each) do
      RailsAdmin.config Employee do
        field :name
        field :email
        field :bonus
        field :income
      end

      visit edit_employee_path(id: employee.id)
    end

    it "shows \"Edit Model\"" do
      expect(page).to have_content("Employee / Edit")
    end

    it "shows required fields as \"Required\"" do
      expect(page).to have_selector("div", :text => /Name\s*Required/)
      expect(page).to have_selector("div", :text => /Email\s*Required/)
    end

    it "shows non-required fields as \"Optional\"" do
      expect(page).to have_selector(".employee_income .help-block", text: "Optional")
    end

    it "displays Delete and Cancel links" do
      expect(page).to have_selector(:link_or_button, 'Cancel')
      expect(page).to have_selector(:link_or_button, 'Delete')
    end
  end

  describe "edit with missing object" do
    before(:each) do
      visit edit_employee_path(id: 600)
    end

    it "raises NotFound" do
      expect(page.driver.status_code).to eq(404)
    end
  end

  context "with accepts_nested_attributes_for" do
    let(:employee_wih_nested) { FactoryGirl.create(:employee_with_all_associations) }

    it "shows nested form fields" do
      visit edit_employee_with_nested_path(employee_wih_nested)

      within("div.nested_fields.nested_form_for_position_attributes") do
        expect(page).to have_field('Name', with: employee_wih_nested.position.name)
      end

      expect(page).to have_css("div.nested_fields.nested_form_for_projects_attributes", :count => 2)
      project = employee_wih_nested.projects.first
      project_forms = all(:css, 'div.nested_fields.nested_form_for_projects_attributes')
      within(project_forms.first) do
        expect(page).to have_field('Name', with: project.name)
        expect(page).to have_field('Description', with: project.description)
        #TODO check tasks
      end
      project = employee_wih_nested.projects[1]
      within(project_forms[1]) do
        expect(page).to have_field('Name', with: project.name)
        expect(page).to have_field('Description', with: project.description)
        #TODO check tasks
      end

      within("div.nested_fields.nested_form_for_account_attributes") do
        expect(page).to have_field('Account number', with: employee_wih_nested.account.account_number)
      end


      expect(page).to have_css("div.nested_fields.nested_form_for_skills_attributes", :count => 2)
      skill = employee_wih_nested.skills.first
      skills_form = all(:css, 'div.nested_fields.nested_form_for_skills_attributes')
      within(skills_form.first) do
        expect(page).to have_field('Name', with: skill.name)
      end
      skill = employee_wih_nested.skills[1]
      within(skills_form[1]) do
        expect(page).to have_field('Name', with: skill.name)
      end

    end

    context "delete button" do
      it "do not show delete button for nested form without allow_destroy", js: true do
        visit edit_employee_with_nested_path(employee_wih_nested)

        within("div.nested_fields.nested_form_for_position_attributes") do
          expect(page).to have_no_selector('span.btn i.icon-trash')
        end

        project_forms = all(:css, 'div.nested_fields.nested_form_for_projects_attributes')
        within(project_forms.first) do
          expect(page).to have_no_selector('span.btn i.icon-trash')
        end
        within(project_forms[1]) do
          expect(page).to have_no_selector('span.btn i.icon-trash')
        end

        within("div.nested_fields.nested_form_for_account_attributes") do
          expect(page).to have_no_selector('span.btn i.icon-trash')
        end

        skills_form = all(:css, 'div.nested_fields.nested_form_for_skills_attributes')
        within(skills_form.first) do
          expect(page).to have_no_selector('span.btn i.icon-trash')
        end
        within(skills_form[1]) do
          expect(page).to have_no_selector('span.btn i.icon-trash')
        end
      end

      it "do show delete button for nested form without allow_destroy", js: true do
        visit edit_employee_with_destroyable_nested_path(employee_wih_nested)

        within("div.nested_fields.nested_form_for_position_attributes") do
          expect(page).to have_selector('span.btn i.icon-trash')
        end

        project_forms = all(:css, 'div.nested_fields.nested_form_for_projects_attributes')
        within(project_forms.first) do
          expect(page).to have_selector('span.btn i.icon-trash')
        end
        within(project_forms[1]) do
          expect(page).to have_selector('span.btn i.icon-trash')
        end

        within("div.nested_fields.nested_form_for_account_attributes") do
          expect(page).to have_selector('span.btn i.icon-trash')
        end

        skills_form = all(:css, 'div.nested_fields.nested_form_for_skills_attributes')
        within(skills_form.first) do
          expect(page).to have_selector('span.btn i.icon-trash')
        end
        within(skills_form[1]) do
          expect(page).to have_selector('span.btn i.icon-trash')
        end
      end
    end

    it "shows button for adding new nested forms for has_many and has_and_belongs_to_many associations" do
      visit edit_employee_with_nested_path(employee_wih_nested)
      expect(page).to have_selector('a.add_nested_fields', text: 'Project')
      expect(page).to have_selector('a.add_nested_fields', text: 'Skill')
    end

    it "do not show buttons for belongs_to and has_one associations" do
      visit edit_employee_with_nested_path(employee_wih_nested)
      expect(page).to have_no_selector('a.add_nested_fields', text: 'Account')
      expect(page).to have_no_selector('a.add_nested_fields', text: 'Position')
    end
  end

  describe "authentication" do
    let(:ability) { Object.new.extend(CanCan::Ability) }

    it "does not show edit page without access" do
      ability.cannot :edit, Employee
      ApplicationController.any_instance.stub(:current_ability).and_return(ability)
      visit edit_employee_path(id: employee)

      expect(page.driver.status_code).to_not eq 200
    end
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

    it "hides displayed field", js:true do
      pending "basepack helper"
      task = FactoryGirl.create(:task, status: 'In progress')
      visit edit_task_path(id: task)
      expect(page).to have_content('Completed percents')

      fill_in "Status", with: "Done"
      fill_in "Description", with: "Test hidding percents"
      expect(page).to have_no_content('Completed percents')
    end

    it "displays hidden field", js: true do
      pending "basepack helper"
      task = FactoryGirl.create(:task, status: 'Done')
      visit edit_task_path(id: task)

      expect(page).to have_no_content('Completed percents')

      fill_in "Status", with: "In progress"
      fill_in "Description", with: "Test hidding percents"

      # sleep 0.2
      expect(page).to have_content('Completed percents')
    end
  end
end

