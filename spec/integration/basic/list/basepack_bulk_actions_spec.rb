require 'spec_helper'

describe "Bulk actions", type: :request do
  let(:task1) { FactoryGirl.create :task }
  let(:task2) { FactoryGirl.create :task }

  let(:tasks) { [task1, task2] }

  let(:ability) { Object.new.extend(CanCan::Ability) }

  context 'with bulk actions enabled' do
    before(:each) do
      RailsAdmin.config Task do
        list do
          bulk_actions true
        end
      end
    end

    context "controls" do
      it 'show checkboxes' do

        task1
        visit tasks_path

        expect(page.driver.status_code).to eq 200
        expect(page).to have_selector("input[type=checkbox]#check_all")
        expect(page).to have_selector("input[name^='bulk_ids[]']", count: 1)
      end

      it 'check all checkboxes', js: true do
        tasks
        visit tasks_path

        find(:css, "input[type=checkbox]#check_all").set(true)
        expect(page).to have_selector("input[name^='bulk_ids[]']:checked",
          count: tasks.count)
      end
    end

    context "actions" do
      context "authorized" do
        it "has Delete all link" do
          task1
          visit tasks_path

          expect(page).to have_selector(:link_or_button, "Delete selected")
        end

        it 'deletes selected items', js: true do
          tasks
          visit tasks_path

          first("input[name^='bulk_ids[]']").set(true)

          click_on "Delete selected"

          expect(page).to_not have_content(tasks[0].name)
          expect(page).to have_content(tasks[1].name)
          expect(page).to have_css("tbody tr", :count => 1)
        end
      end

      context "unauthorized" do
        before(:each) do
          ApplicationController.any_instance.stub(:current_ability).and_return(ability)
        end

        it "does not have Delete all link" do
          ability.cannot :bulk_delete, :all
          task1
          visit tasks_path

          expect(page).to_not have_selector(:link_or_button,
            "Delete selected")
        end

        it "cannot destroy resource", js: true do
          ability.can :manage, :all
          ability.cannot :destroy, Task, id: tasks[0].id
          tasks

          visit tasks_path

          first("input[name^='bulk_ids[]']").set(true)
          click_on "Delete selected"

          expect(page).to have_content(tasks[0].name)
          expect(page).to have_css("tbody tr", :count => 2)
        end

        it 'cannot use bulk_delete', js: true do
          tasks

          ability.can :manage, :all

          visit tasks_path

          first("input[name^='bulk_ids[]']").set(true)
          ability.cannot :bulk_delete, Task
          click_on "Delete selected"

          expect(page.driver.status_code).to_not eq 200
        end
      end
    end
  end

  context 'with bulk actions disabled' do
    before(:each) do
      RailsAdmin.config Task do
        list do
          bulk_actions false
        end
      end
    end

    it 'does not show checkboxes' do
      task1
      visit tasks_path

      expect(page.driver.status_code).to eq 200
      expect(page).not_to have_selector("#check_all")
      expect(page).not_to have_selector("input[name^='bulk_ids[]']",
        count: 1)
    end
  end
end
