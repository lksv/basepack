require 'spec_helper'

def find_node(node)
  find('span.fancytree-node', text: node.to_label)
end

def find_node_expander(node)
  find_node(node).find('span.fancytree-expander')
end

describe "Basepack basic list" do

  let(:ability) { Object.new.extend(CanCan::Ability) }

  let(:project1) { FactoryGirl.create(:project, name: 'Project1.') }
  let(:project2) { FactoryGirl.create(:project, name: 'Project2.') }

  let(:project11) { FactoryGirl.create(:project, name: 'Project1-1.', parent: project1) }
  let(:project12) { FactoryGirl.create(:project, name: 'Project1-2.', parent: project1) }
  let(:project13) { FactoryGirl.create(:project, name: 'Project1-3.', parent: project1) }

  let(:project21) { FactoryGirl.create(:project, name: 'Project2-1.', parent: project2) }
  let(:project22) { FactoryGirl.create(:project, name: 'Project2-2.', parent: project2) }

  let(:project121) { FactoryGirl.create(:project, name: 'Project1-2-1.', parent: project12) }
  let(:project122) { FactoryGirl.create(:project, name: 'Project1-2-2.', parent: project12) }
  let(:project123) { FactoryGirl.create(:project, name: 'Project1-2-3.', parent: project12) }

  let(:tree) do
    [project1, project2, project11, project12, project13, project21, 
     project22, project121, project122, project123]
  end

  before(:each) do
    RailsAdmin.config Project do
      tree_list do
        bulk_actions true
        #extensions ["dnd", "gridnav", "persist"]
      end
    end
  end

  describe "drag and drop" do
    before(:each) do
      RailsAdmin.config Project do
        tree_list do
          bulk_actions true
          extensions ["dnd", "gridnav", "persist"]
        end
      end
    end

    it "moves node orver", js: true do
      pending "not woring in Poltergeist" if Capybara.javascript_driver === :poltergeist

      tree
      visit projects_path
      find_node_expander(project1).click
      find_node_expander(project12).click

      find_node(project122).drag_to(find_node(project2))

      expect(page).to have_no_content(project122.to_label)
      find_node_expander(project2).click
      expect(page).to have_content(project122.to_label)

      expect(page.body).to match(/#{Regexp.escape(project2.to_label)}.*#{Regexp.escape(project122.to_label)}/)
      visit projects_path
      expect(page).to have_content(project11.to_label)
    end

    #TODO
    #it "moves node before" do
    #  pending "TODO"
    #end

    #it "moves node after" do
    #  pending "TODO"
    #end

    context "unauthorized" do
      it "rejects update_list", js: true do
        pending "not woring in Poltergeist" if Capybara.javascript_driver === :poltergeist

        ability.can :manage, :all
        ability.cannot :update_tree, Project
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)

        tree
        visit projects_path

        find_node(project1).drag_to(find_node(project2))

        expect(page).to have_content('Internal Server Error')
        visit projects_path
        expect(page.body).to match(/#{Regexp.escape(project1.to_label)}.*#{Regexp.escape(project2.to_label)}/)
      end
    end
  end

  describe "collapse and expands" do
    it "shows only root nodes by default", js: true do
      tree
      visit projects_path

      expect(page).to have_content(project1.to_label)
      expect(page).to have_content(project2.to_label)

      expect(page).to have_no_content(project11.to_label)
      expect(page).to have_no_content(project12.to_label)
      expect(page).to have_no_content(project21.to_label)
      expect(page).to have_no_content(project22.to_label)
    end

    it "shlould expand and collapse a node", js: true do
      tree
      visit projects_path

      find_node_expander(project1).click
      expect(page).to have_content(project12.to_label)
      find_node_expander(project12).click
      expect(page).to have_no_content(project122.to_label)

      find_node_expander(project1).click
      expect(page).to have_no_content(project12.to_label)
      expect(page).to have_no_content(project122.to_label)
    end

    it "should remember the expanded status of collabed node", js:true do
      tree
      visit projects_path

      find_node_expander(project1).click
      find_node_expander(project12).click
      find_node_expander(project1).click

      visit projects_path

      find_node_expander(project1).click
      expect(page).to have_content(project12.to_label)
      expect(page).to have_no_content(project122.to_label)
    end

  end

  describe "responses" do
    it "success code with :html", js: true do
      tree
      visit projects_path
      expect(page.driver.status_code).to eq 200
    end

    context "unauthorized" do
      it "rejects list" do
        ability.can :manage, :all
        ability.cannot :index, Project
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)
        visit projects_path
        expect(page.driver.status_code).not_to eq 200
      end
    end
  end

  describe "actions" do
    context "authorized" do
      it "has Show, Add new, Edit and Delete links", js: true do
        project1
        visit projects_path

        expect(page.driver.status_code).to eq 200
        expect(page).to have_selector(:link_or_button, "Show")
        expect(page).to have_selector(:link_or_button, "Edit")
        expect(page).to have_selector(:link_or_button, "Add new")
        expect(page).to have_selector(:link_or_button, "Delete")
      end

      it "displays show page", js: true do
        project1
        visit projects_path
        within(find_node(project1)) do
          click_on "Show"
        end
        expect(current_path).to eq project_path(id: project1.id)
      end

      it "displays edit page", js: true do
        project1
        visit projects_path
        sleep 5
        within(find_node(project1)) do
          click_on "Edit"
        end
        expect(current_path).to eq edit_project_path(id: project1.id)
      end

      it "displays new page", js: true do
        project1
        visit projects_path
        click_on "Add new"
        expect(current_path).to eq new_project_path
      end

      it "deletes an project", js: true do
        project1
        visit projects_path

        within(find_node(project1)) do
          click_on "Delete"
        end
        page.driver.browser.switch_to.alert.accept rescue nil
        page.driver.browser.accept_js_confirms rescue nil

        expect(page).to have_no_content(project1.to_label)
        expect(page).to have_css("tbody li", :count => 0)
      end
    end

    context "unauthorized" do
      before(:each) do
        ability.can :manage, :all
        ApplicationController.any_instance.stub(:current_ability).and_return(ability)
      end

      it "without Show link and access", js: true do
        ability.cannot :show, Project

        project1
        visit projects_path
        expect(page).to have_no_selector(:link_or_button, "Show")

        visit project_path(project1)
        expect(page.driver.status_code).to_not eq 200
      end

      it "without Edit link and access", js: true do
        ability.cannot :edit, Project

        project1
        visit projects_path
        expect(page).to have_no_selector(:link_or_button, "Edit")

        visit edit_project_path(project1)
        expect(page.driver.status_code).to_not eq 200
      end

      it "without Add new link and access", js: true do
        ability.cannot :create, Project

        visit projects_path
        expect(page).to have_no_selector(:link_or_button, "Add new")

        visit new_project_path
        expect(page.driver.status_code).to_not eq 200
      end

      it "without Delete link and permission", js: true do
        ability.cannot :destroy, Project

        project1
        visit projects_path
        expect(page).to have_no_selector(:link_or_button, /\ADelete\Z/)
      end
    end
  end

  describe "sorting" do
    before(:each) do
      RailsAdmin.config Project do
        tree_list do
          bulk_actions true
        end
      end
    end

    it "sorts by position", js: true do
      tree
      project1.update_attribute(:position, 1)
      project2.update_attribute(:position, 2)
      visit projects_path
      expect(page.body).to match(/#{Regexp.escape(project1.to_label)}.*#{Regexp.escape(project2.to_label)}/)
      project1.update_attribute(:position, 2)
      project2.update_attribute(:position, 1)
      visit projects_path
      expect(page.body).to match(/#{Regexp.escape(project2.to_label)}.*#{Regexp.escape(project1.to_label)}/)
    end
  end

  describe "filters" do
    describe "default filter" do
      before(:each) do
        tree
        ProjectsController.any_instance.stub(:default_query_params).and_return(
          { "f[name_cont]" => "1" }
        )
      end

      it "uses default filter when no search params provided", js: true do
        visit projects_path

        expect(page).to have_content(project1.to_label)
        expect(page).to have_no_content(project2.to_label)
      end

      it "do not use default filter when search params provided", js: true do
        visit projects_path('f[name_not_eq]' => '123')

        expect(page).to have_content(project1.to_label)
        expect(page).to have_content(project2.to_label)
      end
    end

    it "correctly filters contains", js: true  do
      pending 'future work'
      #NEW FEATURE REQUIRED:
      # show tree accoring the filter, e.g.
      # for the collection find the upperset - parents of all items from the filter
      # change load_tree_nodes to use only items form such collection.

      # e.g. If I filter for sub-sub-item, I can see this item nested in the tree.
      visit projects_path('f[name_cont]' => '1-2-3')

      expect(page).to have_content(project123.to_label)
      expect(page).to_not have_content(project2.to_label)
    end
  end
end
