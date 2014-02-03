require 'spec_helper'

describe "Basepack basic update" do
  # subject { page }

  let!(:employee1) { FactoryGirl.create :employee }
  let!(:employee_with_projects) { FactoryGirl.create :employee_with_projects }

  #let(:ability) { Object.new.extend(CanCan::Ability) }

  describe "update with errors" do

   it "does not allow to change id" do
     employee1.id
     new_id = 10000
     page.driver.submit :put, "/employees/#{employee1.id}", { employee: { id: new_id } }
     expect(page.driver.status_code).to eq 200

     expect(Employee.exists?(new_id)).to be_false
     expect(Employee.exists?(employee1.id)).to be_true
    end

    it "returns to edit page" do
      visit edit_employee_path(id: employee1)
      fill_in "Name", with: ""

      click_on "Save"
      expect(page).to have_content("Some errors were found, please take a look:")
    end

    it "update with missing object" do
      page.driver.submit :put, "/employees/42", { employee: { name: "Paul Dot", email: "dot@gmail.com" } }

      expect(page.driver.status_code).to_not eq 200
    end
  end


  describe "update without association" do

    it "updates an object with correct attribute" do
      visit edit_employee_path(id: employee1)
      fill_in "employee[name]", with: "John Smith"
      click_on "Save"

      expect(page).to have_content("Employee successfully updated")
      employee1.reload
      expect(current_path).to eq employee_path(employee1)

      expect(employee1.name).to eq("John Smith")
    end
  end

  describe "update belongs_to" do
    before(:each) do
      RailsAdmin.config Employee do 
        edit do
          field :position
        end
      end
    end

    it "adds position" do
      pending "basepack helper not working properly"
      position = FactoryGirl.create(:position)
      visit edit_employee_path(id: employee1)

      add_select2 "Position", with: position.to_label
      click_on "Save"

      employee1.reload      
      expect(employee1.position.id).to eq(position.id) 
    end

  end

  describe "update has_one association", js: true do
    before(:each) do
      RailsAdmin.config Employee do 
        edit do
          field :account
        end
      end
    end

    it "adds account" do
      pending "basepack helper not working properly"
      account = FactoryGirl.create(:account)
      visit edit_employee_path(id: employee1)

      add_select2 "Account", with: account.to_label
      click_on "Save"

      employee1.reload      
      expect(employee1.account.id).to eq(account.id) 
    end

    
  end

  describe "update has_many associations", js: true do
    let!(:employee_with_projects) { FactoryGirl.create(:employee_with_projects) }

    it "adds project" do
      project = FactoryGirl.create(:project)
      visit edit_employee_path(id: employee1)

      add_select2 "Projects", with: project.to_label
      click_on "Save"

      employee1.reload      
      expect(employee1.project_ids).to include(project.id) 
    end

    it "removes all projects", js:true do
      RailsAdmin.config Employee do
        edit do
          field :projects
        end
      end
      visit edit_employee_path(id: employee_with_projects)
      
      remove_all_select2 "Projects"
      click_on "Save"

      employee_with_projects.reload      
      expect(employee_with_projects.project_ids).to be_empty
    end

    it "removes 1 project", js:true do
      RailsAdmin.config Employee do
        edit do
          field :projects
        end
      end
      visit edit_employee_path(id: employee_with_projects)
      
      remove_select2 "Projects", with: employee_with_projects.projects.first.to_label
      project = employee_with_projects.projects.last
      click_on "Save"

      employee_with_projects.reload      
      expect(employee_with_projects.projects).to eq([project])
    end
  end

  describe "has_and_belongs_to_many association", js: true do
    let!(:employee_with_skills) { FactoryGirl.create(:employee_with_skills)  }
    
    before(:each) do
      RailsAdmin.config Employee do
        edit do
          field :skills
        end
      end
    end

    it "adds skill" do
      skill = FactoryGirl.create(:skill)
      visit edit_employee_path(id: employee1)

      add_select2 "Skills", with: skill.to_label
      click_on "Save"

      employee1.reload      
      expect(employee1.skill_ids).to include(skill.id) 
    end

    it "removes all skills", js:true do
      visit edit_employee_path(id: employee_with_skills)
      
      remove_all_select2 "Skills"
      click_on "Save"

      employee_with_skills.reload      
      expect(employee_with_skills.skill_ids).to be_empty
    end

    it "removes 1 skill", js:true do
      visit edit_employee_path(id: employee_with_skills)
      
      remove_select2 "Skills", with: employee_with_skills.skills.first.to_label
      skill = employee_with_skills.skills.last
      click_on "Save"

      employee_with_skills.reload      
      expect(employee_with_skills.skills).to eq([skill])
    end
  end

  describe "has_many through association", js: true do
    # projects contain tasks
    let!(:employee_with_projects) { FactoryGirl.create(:employee_with_projects) }

    before(:each) do
      RailsAdmin.config Employee do
        edit do
          field :tasks
        end
      end
    end

    it "adds task" do
      pending "raising exception can't modify has_many through association"
      task = FactoryGirl.create(:task)
      visit edit_employee_path(id: employee1)

      add_select2 "Tasks", with: task.to_label
      click_on "Save"

      employee1.reload      
      expect(employee1.task_ids).to include(task.id) 
    end
    
  end

  let(:ability) { Object.new.extend(CanCan::Ability) }
  describe "authentication" do

    it "does not allow to update record" do
      employee1
      ability.cannot :update, Employee
      ApplicationController.any_instance.stub(:current_ability).and_return(ability)

      page.driver.submit :put, "/employees/#{employee1.id}", { employee: { name: "updated name" } }
      expect(page.driver.status_code).to_not eq 200
      employee1.reload
      expect(employee1.name).to_not eq "updated name"
    end
  end

  context "without accepts_nested_attributes_for" do
    it "igonres nested attributes id and _destroy" do      
      employee_with_projects

      page.driver.submit :put, "/employees/#{employee_with_projects.id}", { 
        employee: { 
          name: "updated name", 
          projects_attributes: {
            "0" => { id: employee_with_projects.projects[0].id, name: "great first project", "_destroy" => true }, 
            "1" => { id: employee_with_projects.projects[1].id, name: "destroy project", "_destroy" => true } 
          }
        } 
      }
      
      employee_with_projects.reload
      expect(page.driver.status_code).to eq 200
      expect(employee_with_projects.name).to eq "updated name"
      expect(employee_with_projects.projects[0].name).to_not eq "great first project"
      expect(employee_with_projects.projects[1]).to_not be_nil
    end
  end

  context "with accepts_nested_attributes_for" do
    context 'without allow_destroy' do
      it "igonres _destroy" do      
        employee_with_projects

        page.driver.submit :put, "/employee_with_nesteds/#{employee_with_projects.id}", { 
          employee_with_nested: { 
            name: "updated name", 
            projects_attributes: {
              "1" => { id: employee_with_projects.projects[1].id, name: "destroy project", "_destroy" => true } 
            }
          } 
        }
        
        employee_with_projects.reload
        expect(page.driver.status_code).to eq 200
        expect(employee_with_projects.name).to eq "updated name"
        expect(employee_with_projects.projects[1]).to_not be_nil
      end

      it "updates nested projects form fields" do
        visit edit_employee_with_nested_path(employee_with_projects)
        # save_and_open_page
        fill_in "employee_with_nested_projects_attributes_0_name", with: "updated project name 1"
        fill_in "employee_with_nested_projects_attributes_1_name", with: "updated project name 2"
        click_on "Save"

        employee_with_projects.reload
        expect(employee_with_projects.projects[0].name).to eq "updated project name 1"
        expect(employee_with_projects.projects[1].name).to eq "updated project name 2"
      end

      it "adds nested form items", js: true do
        visit edit_employee_with_nested_path(employee1)
        expect{
          click_on "Project"
          within(".employee_with_nested_projects_name") do
            fill_in "Name", with: "new nested project"
          end
          click_on "Save"
        }.to change(Project, :count).by(1)
        expect(employee1.projects.count).to eq 1
        expect(employee1.projects[0].name).to eq "new nested project"
      end
    end

    context 'with allow_destroy' do
      it "destroys when _destroy param present" do      
        employee_with_projects

        page.driver.submit :put, "/employee_with_destroyable_nesteds/#{employee_with_projects.id}", { 
          employee_with_destroyable_nested: { 
            name: "updated name", 
            projects_attributes: {
              "1" => { id: employee_with_projects.projects[1].id, name: "destroy project", "_destroy" => true } 
            }
          } 
        }
        
        employee_with_projects.reload
        expect(page.driver.status_code).to eq 200
        expect(employee_with_projects.name).to eq "updated name"
        expect(employee_with_projects.projects.count).to eq 1
      end

      it "deletes nested form items", js: true do
        visit edit_employee_with_destroyable_nested_path(employee_with_projects)
        find("#employee_with_destroyable_nested_projects_attributes_0__destroy+ .remove_nested_fields .btn-danger").click
        click_on "Save"
        expect(employee_with_projects.projects.count).to eq 1
      end
    end
  end
end
