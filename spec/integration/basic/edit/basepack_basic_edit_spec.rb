require 'spec_helper'

describe "Basepack Basic Edit" do

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


end

