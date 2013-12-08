require 'spec_helper'

describe "Lepidlo Basic Show" do
  # subject { page }

  # TODO separate to actions and responses   
  describe "fields without association" do
    before do
      @employee = FactoryGirl.create :employee
    end

    it "has Edit, Delete and attributes" do
      RailsAdmin.config Employee do
        show do
          include_all_fields
        end
      end
      visit employee_path(:id => @employee.id)
      expect(page).to have_selector("a", :text => "Edit")
      expect(page).to have_selector("a", :text => "Delete")
      
      Employee.attribute_names.each do |attr|
        next if attr.in?(["id", "created_at", "updated_at"])
        expect(page).to have_content(Employee.human_attribute_name(attr))
        expect(page).to have_content(@employee.send(attr))
      end
    end

    it "shows only defined columns" do
      RailsAdmin.config Employee do
        show do
          field :name
          field :income
        end
      end

      visit employee_path(:id => @employee.id)
      
      expect(page).to have_content(@employee.name)
      expect(page).to have_content(@employee.income)

      expect(page).to have_no_content(@employee.email)
    end

    it "properly format date columns" do
      RailsAdmin.config Employee do
        show do
          field :name
          field :created_at
        end
      end

      visit employee_path(:id => @employee.id)

      expect(page).to have_content(I18n.l @employee.created_at, format: :long)
    end

    it "properly shows boolean field type" do
        RailsAdmin.config Employee do
          show do
            field :bonus
          end
        end
        @employee.update_attributes(bonus: false)

        visit employee_path(:id => @employee.id)
        
        expect(page).to have_content("Bonus")
        expect(page).to have_content("✘")
    end

    describe "belongs_to association" do
      before(:each) do
        RailsAdmin.config Employee do
          show do
            field :position
          end
        end        
      
        @employee.position = FactoryGirl.create(:position, name: "My Position")
        @employee.save!
      end
      
      context "when has access" do
        it "it shows as link" do
          visit employee_path(:id => @employee.id)
          expect(page).to have_content('My Position')
        end
      end

      #TODO: rozdelit na dva testcasy - jeden se zakazanym ablity na cannot :show, Position (ten to zobrazi pouze jako text) a druhy s povoleny, pro ten to bude link
      #should_not have_selector(:link_or_button, 'My Position')
    end


    # it "responses with :json" do
    #   visit employees_path(:format => :json)
    #   expect(ActiveSupport::JSON.decode(page.body).length).to eq(2)
    #   ActiveSupport::JSON.decode(page.body).each do |object|
    #     expect(object).to have_key("id")
    #     expect(object).to have_key("name")
    #     expect(object).to have_key("email")
    #     expect(object).to have_key("created_at")
    #     expect(object).to have_key("updated_at")
    #   end
    # end

    # it "responses with :xml" do
    #   pending "add some examples to (or delete) #{__FILE__}"
    # end

  end

  describe "has_many association" do
    before(:each) do
      @employee = FactoryGirl.create :employee
      @task1 = FactoryGirl.create :task, :employee_id => @employee.id, description: "first task"
      @task2 = FactoryGirl.create :task, :employee_id => @employee.id, description: "second task"

      RailsAdmin.config Employee do
        field :tasks
      end
      visit employee_path(:id => @employee.id)
    end

    # TODO without access not as links
    it "shows associated objects" do      
      expect(page).to have_content('first task and second task')
      expect(page).to have_selector(:link_or_button, 'first task')
      expect(page).to have_selector(:link_or_button, 'second task')
    end
  end


=begin
  describe "GET employees/123this-id-doesnt-exist" do
    it "raises NotFound" do
      visit 'employees/123this-id-doesnt-exist'
      expect(page.driver.status_code).to eq(404)
    end
  end

  describe "show with belongs_to association" do
    before(:each) do
      @employee = FactoryGirl.create :employee
      @team   = FactoryGirl.create :team
      @employee.update_attributes(:team_id => @team.id)
      visit employee_path(:id => @employee.id)
    end

    it "shows associated objects" do
      expect(page).to have_css("a[href='/admin/team/#{@team.id}']")
    end
  end

  describe "show with has-one association" do
    before(:each) do
      @employee = FactoryGirl.create :employee
      @draft  = FactoryGirl.create :draft, :employee => @employee
      visit employee_path(:id => @employee.id)
    end

    it "shows associated objects" do
      should have_css("a[href='/admin/draft/#{@draft.id}']")
    end
  end

  describe "show with has-and-belongs-to-many association" do
    before(:each) do
      @employee = FactoryGirl.create :employee
      @comment1 = FactoryGirl.create :comment, :commentable => @employee
      @comment2 = FactoryGirl.create :comment, :commentable => @employee
      @comment3 = FactoryGirl.create :comment, :commentable => FactoryGirl.create(:employee)

      visit employee_path(:id => @employee.id)
    end

    it "shows associated objects" do
      should have_css("a[href='/admin/comment/#{@comment1.id}']")
      should have_css("a[href='/admin/comment/#{@comment2.id}']")
      should_not have_css("a[href='/admin/comment/#{@comment3.id}']")
    end
  end

  describe "show for polymorphic objects" do
    before(:each) do
      @employee = FactoryGirl.create :employee
      @comment = FactoryGirl.create :comment, :commentable => @employee
      visit employee_path(:model_name => "comment", :id => @comment.id)
    end

    it "shows associated object" do
      should have_css("a[href='/admin/employee/#{@employee.id}']")
    end
  end
=end
end