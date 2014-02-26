require 'spec_helper'
describe "Basepack Basic Bulk Edit" do
  describe "GET /employees/bulk_edit edit form" do
    before(:each) do
      RailsAdmin.config Employee do
        field :name
        field :email
        field :bonus
        field :income
        field :account
        field :position
        field :tasks
        field :skills
      end

      visit bulk_edit_employees_path
    end

    it "shows \"Bulk edit\"" do
      expect(page).to have_content("Employees / Bulk edit")
    end

    it "disable required validation for required fields" do
      expect(page).not_to have_selector("label.required", text: /Name/)
      expect(page).not_to have_selector("label.required", text:  /Email/)
    end

    it "displays bulk_action selection for N:N associations fields" do
      #it do not displays task_ids because it is not N-N association
      #N-N associations are:
      #  has_and_belongs_to_many
      #  has_many through: <join_table>, where join_table has foreign_keys for both associations
      expect(page).to have_selector('select[name="employee[bulk_edit][skill_ids]"]')
    end

    it "does not display bulk_aciton selection for belongs_to and has_many" do
      expect(page).to_not have_selector('select[name="employee[bulk_edit][project_ids]"]')
      expect(page).to_not have_selector('select[name="employee[bulk_edit][task_ids]"]')
    end

  end

  describe "update", js: true do
    let!(:employee1) { FactoryGirl.create(:employee_with_all_associations) }
    let!(:employee2) { FactoryGirl.create(:employee_with_all_associations) }
    let!(:employee3) { FactoryGirl.create(:employee_with_all_associations) }

    it "take filter params and show number of edited items" do
      visit bulk_edit_employees_path('f[id_lt]' => employee3.id)
      expect(page).to have_content("Bulk edit for 2 items")
    end

    context "boolean type" do
      it "updates boolean type to specified value" do
        employee1.bonus = false
        employee1.save!

        visit bulk_edit_employees_path
        select 'Check', from: "employee[bonus]"
        click_on "Save"
        expect(current_path).to eq employees_path
        employee1.reload
        expect(employee1.bonus).to be_true

        visit bulk_edit_employees_path
        select 'Uncheck', from: "employee[bonus]"
        click_on "Save"
        expect(current_path).to eq employees_path
        employee1.reload
        expect(employee1.bonus).to be_false
      end

      it "should not update boolean type if not changed" do
        employee1.update_attribute(:bonus, true)
        employee2.update_attribute(:bonus, false)
        employee3.update_attribute(:bonus, nil)

        visit bulk_edit_employees_path
        fill_in "employee[income]", with: "1500"
        click_on "Save"

        employee1.reload
        employee2.reload
        employee3.reload

        expect(employee1.bonus).to be_true
        expect(employee2.bonus).to be_false
        expect(employee3.bonus).to be_nil
      end
    end

    it "take filter params and show number of edited items", js: true do
      skill = FactoryGirl.create(:skill)

      visit bulk_edit_employees_path('f[id_lt]' => employee3.id)

      fill_in "employee[name]", with: "John Smith"
      fill_in "employee[email]", with: "john.smith@gmail.com"
      fill_in "employee[income]", with: "1500"
      add_select2('Skills', with: skill.to_label)
      click_on "Save"

      expect(current_path).to eq employees_path

      employee1.reload
      employee2.reload
      employee3.reload

      expect(employee1.name).to eq "John Smith"
      expect(employee2.name).to eq "John Smith"
      expect(employee3.name).to_not eq "John Smith"

      expect(employee1.email).to eq "john.smith@gmail.com"
      expect(employee2.email).to eq "john.smith@gmail.com"
      expect(employee3.email).to_not eq "john.smith@gmail.com"

      expect(employee1.income).to eq 1500
      expect(employee2.income).to eq 1500
      expect(employee3.income).to_not eq 1500


      expect(employee1.skills).to include(skill)
      expect(employee2.skills).to include(skill)
      expect(employee3.skills).to_not include(skill)
    end

    it "assing nested selected items from N:N association", js: true do
      skill = FactoryGirl.create(:skill)

      visit bulk_edit_employees_path('f[id_lt]' => employee3.id)

      find('select[name="employee[bulk_edit][skill_ids]"]').find(:option, 'assign', {}).select_option
      add_select2('Skills', with: skill.to_label)

      click_on "Save"

      employee1.reload
      employee2.reload
      employee3.reload

      expect(employee1.skills).to eq [skill]
      expect(employee2.skills).to eq [skill]
      expect(employee3.skills).to_not include(skill)
    end

    it "delete nested selected items from N:N association", js: true do
      skill = employee2.skills.first

      visit bulk_edit_employees_path('f[id_lt]' => employee3.id)

      find('select[name="employee[bulk_edit][skill_ids]"]').find(:option, 'delete', {}).select_option
      add_select2('Skills', with: skill.to_label)

      click_on "Save"

      employee1.reload
      employee2.reload
      employee3.reload

      expect(employee2.skills).to_not include(skill)
    end
  end

  describe "section" do
    context "with bulk_edit section diferent from edit section" do
      before(:each) do
        RailsAdmin.config Employee do
          edit do
            field :email
          end

          bulk_edit do
            exclude_fields :email
            field :name
            field :skills
          end
        end
      end

      it "shows only fields for edit section" do
        visit bulk_edit_employees_path
        expect(page).to_not have_field('Email')
        expect(page).to have_field('Name')
        expect(page).to have_selector('select[name="employee[bulk_edit][skill_ids]"]')
      end
    end
  end
end
