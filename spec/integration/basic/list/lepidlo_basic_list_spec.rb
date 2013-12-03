require 'spec_helper'
include Warden::Test::Helpers
include Devise::TestHelpers

describe "Lepidlo basic list" do
  subject { page }

  describe "GET /customers" do

    context "list defined columns" do
      before do
        @customers  = 2.times.map { FactoryGirl.create :customer }
      end

      it "shows all fields when form is not defined" do
        visit customers_path
        Customer.attribute_names.each do |attr|
          should have_content(Customer.human_attribute_name(attr))
        end
      end

      it "show only defined columns" do
        RailsAdmin.config Customer do
          list do
            field :name
          end
        end

        visit customers_path()

        should have_content(@customers[0].name)
        should have_content(@customers[1].name)
        should have_no_content(@customers[0].email)
        should have_no_content(@customers[1].email)
      end

      it "properly format date columns" do
        RailsAdmin.config Customer do
          list do
            field :name
            field :created_at
          end
        end

        visit customers_path()
        should have_content(I18n.l @customers.first.created_at, format: :long)
      end

      it "properly shows belongs_to association" do
        RailsAdmin.config Customer do
          list do
            field :group
          end
        end
        @customers.first.group = FactoryGirl.create(:group, name: 'My Group')
        @customers.first.save!

        visit customers_path
        should have_content('My Group')
        #TODO: rozdelit na dva testcasy - jeden se zakazanym ablity na cannot :show, Group (ten to zobrazi pouze jako text) a druhy s povoleny, pro ten to bude link
        #should_not have_selector(:link_or_button, 'My Group')
      end

      describe "properly shows has_many association" do
        before do
          RailsAdmin.config Customer do
            list do
              field :comments
            end
          end
          customer = @customers.first
          customer.comments.build(body: 'first comment')
          customer.comments.build(body: 'second comment')
          customer.save!
        end

        it "show only text" do
          #TODO: cannot :show, Comment
          #visit customers_path
          #should have_content('first comment and second comment')
          #should_not have_selector(:link_or_button, 'first comment')
          #should_not have_selector(:link_or_button, 'first comment')
        end

        it "shows as links" do
          visit customers_path
          should have_content('first comment and second comment')
          should have_selector(:link_or_button, 'first comment')
          should have_selector(:link_or_button, 'first comment')
        end
      end

      it "properly shows boolean field type" do
        pending "add some examples to (or delete) #{__FILE__}"
      end

      it "respons with :json" do
        visit customers_path(:format => :json)
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
    end

    describe "pagination" do
      before do
        #FIXME: setting RailsAdmin items_pare_page do not work for me:( decrease the creating objects to 5.
        53.times { FactoryGirl.create(:customer) }
        RailsAdmin.config.default_items_per_page = 1
        RailsAdmin.config Customer do
          list do
            items_per_page 1
          end
        end
        visit customers_path(:page => 2)
      end

      it "shows total number of items" do
        should have_content('53 in total')
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
        @c1 = FactoryGirl.create(:customer, name: 'xxx')
        @c2 = FactoryGirl.create(:customer, name: 'yyy')
        @c3 = FactoryGirl.create(:customer, name: 'xxxx')
      end

      describe "default filter" do
        before do
          CustomersController.default_query do
            { "f[name_eq]" => "xxx" }
          end
        end

        it "uses default filter when no search params provided" do
          visit customers_path

          should have_content(@c1.name)
          should have_no_content(@c2.name)
          should have_css("tbody tr", :count => 1)
        end

        it "do not use default filter when search params provided" do
          visit customers_path('f[name_not_eq]' => '123')

          should have_content(@c1.name)
          should have_content(@c2.name)
          should have_content(@c3.name)
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
