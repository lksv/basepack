module Basepack
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)

      desc "Creates a Basepack initializer and copy locale files to your application."

      def self.next_migration_number(path)
        if ActiveRecord::Base.timestamped_migrations
          sleep 1 # make sure each time we get a different timestamp
          Time.new.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(path) + 1)
        end
      end

      def add_assets
        js_manifest = 'app/assets/javascripts/application.js'
        if File.exist?(js_manifest)
          insert_into_file js_manifest, "//= require jquery\n", :before => "\n//= require"
          insert_into_file js_manifest, "//= require basepack\n", :after => "jquery_ujs\n"
          insert_into_file js_manifest, "//= require jquery.turbolinks\n", :after => "jquery\n"
        else
          copy_file "application.js", js_manifest
        end

        css_manifest = 'app/assets/stylesheets/application.css'
        scss_manifest = 'app/assets/stylesheets/application.css.scss'
        if File.exist?(css_manifest)
          content = File.read(css_manifest)
          insert_into_file css_manifest, " *= require basepack\n *= require basepack_and_overrides\n", :after => "require_self\n"
          copy_file "basepack_and_overrides.css", "app/assets/stylesheets/basepack_and_overrides.css"
        elsif File.exists?(scss_manifest)
          content = File.read(scss_manifest)
          append_file scss_manifest, '@import "basepack";'
          append_file scss_manifest, '@import "basepack_and_overrides";'
          copy_file "basepack_and_overrides.css", "app/assets/stylesheets/basepack_and_overrides.css"
        else
          copy_file "application.css.scss", "app/assets/stylesheets/application.css.scss"
        end
      end

      def check_cancan
        if !defined?(Devise) #and yes?("Would you like to install CanCan?")
          gem 'cancan'
          generate "cancan:ability"
        end
      end

      def check_devise
        #othervise error: undefined local variable or method `current_user'
        if !defined?(CanCan) #and yes?("Would you like to install Devise?")
          gem "devise"
          generate "devise:install"
          model_name = ask("What would you like the user model to be called? [user]")
          model_name = "user" if model_name.blank?
          generate "devise", model_name
        end
      end

      def add_dependant_gems
        gem 'jquery-turbolinks'
        gem 'inherited_resources',  '~> 1.4.1'
        gem 'ransack',              '~> 1.0'
        gem 'kaminari',             '~> 0.15.1'
        gem 'simple_form',          '~> 3.0.1'
        gem 'settingslogic',        '~> 2.0.9'

        #needs to be set exactly because of incompatibility bootstrap-modal-rails
        #TODO fix when new version of bootstrap-modal-rails will be released
        gem 'twitter-bootstrap-rails', '~> 2.2.7'
        gem 'bootbox-rails'

        #needed for imports
        gem 'delayed_job_active_record', '~> 4.0.0'

        #used in filters
        gem 'strip_attributes', '~> 1.2'

      end

      #for Image/assets management (used also in imports)
      def add_dragonfly
        gem 'rack-cache', :require => 'rack/cache'
        gem 'dragonfly', '~> 1.0.2'
        generate 'dragonfly'
      end

      def copy_files
        template "basepack-settings.yml", "config/basepack-settings.yml"
        copy_file "../../../../config/locales/en.yml", "config/locales/basepack.en.yml"
        directory 'layouts', 'app/views/layouts/'
        copy_file "resources_controller.rb", "app/controllers/resources_controller.rb"

        app_file = 'app/views/layouts/application.html.erb'
        if File.exists?(app_file) and yes?("Can I remove #{app_file}?")
          run("rm #{app_file}")
        end

        insert_into_file 'config/routes.rb', :after => "draw do\n" do <<-'RUBY'
  concern :resourcable do
      get    'options',     :on => :collection
      get    'query',       :on => :collection
      post   'query',       :on => :collection
      get    'export',      :on => :collection
      post   'export',      :on => :collection
      get    'import',      :on => :collection
      post   'import',      :on => :collection
      patch  'import',      :on => :collection
      delete 'import',      :on => :collection
      delete 'bulk_delete', :on => :collection

      get    'filters',     :on => :collection
      get    'export_templates', :on => :collection
      get    'taggings',     :on => :collection
      #patch  'list_columns', :on => :collection
      #put    'list_columns', :on => :collection

      get    'bulk_edit',     on: :collection
      patch  'bulk_update',   on: :collection
      post   'bulk_update',   on: :collection
      post 'update_parent',   on: :member
      post 'load_tree_nodes', on: :member
      get  'load_tree_nodes', on: :member
end

  resources :filters, concerns: :resourcable
  resources :export_templates, concerns: :resourcable

  # Uncomment if you are going to use tags (you also need get "acts-as-taggable-on")
  #
  # resources :acts_as_taggable_on_tags, concerns: :resourcable

  # Exampe of controller which merge action:
  #
  # resources :customers do
  #   get    'diff/:id2',   on: :member, to: :diff, as: :diff    #for showing a diff page
  #   post   'merge/:id2',  on: :member, to: :merge, as: :merge  #for mege action
  # end

RUBY
        end
      end

      def rails_admin_init_script
        rails_admin_cfg_file = 'config/initializers/rails_admin.rb'
        if File.exist?(rails_admin_cfg_file)
          insert_into_file rails_admin_cfg_file, "  config.included_models = Basepack::Utils.detect_models #+ ['ActsAsTaggableOn::Tag', 'Delayed::Job']\n", :before => "end\n"
        else
          copy_file "rails_admin.rb", rails_admin_cfg_file
        end
      end

      def create_imports
        #TODO - should I ask whether generate?
        copy_migrate 'create_imports'
        copy_migrate 'create_imports_importables_join_table'
        copy_file 'import.rb', 'app/models/import.rb'
        user_model_file =  'app/models/user.rb'
        if File.exists?(user_model_file)
          insert_into_file user_model_file, "  has_many :imports, inverse_of: :user\n", :after => "class User < ActiveRecord::Base\n"
        end
      end

      def create_saved_filters
        #TODO - should I ask whether generate?
        copy_migrate 'create_filters'
        copy_file 'filter.rb', 'app/models/filter.rb'
        copy_file 'filters_controller.rb', 'app/controllers/filters_controller.rb'

        copy_migrate 'create_export_templates'
        copy_file 'export_template.rb', 'app/models/export_template.rb'
        copy_file 'export_templates_controller.rb', 'app/controllers/export_templates_controller.rb'

        ability_model_file = 'app/models/ability.rb'
        if File.exists?(ability_model_file)
          insert_into_file(ability_model_file, <<-EOF,
    # FIXME: change abilities according your needs
    can :manage, :all

    # Everybody can see others saved filter, but only author can mangage them.
    can :read, Filter
    can :manage, Filter, :user_id => user.id if user

    can :read, ExportTemplate
    can :manage, ExportTemplate, :user_id => user.id if user
EOF
          :after => "def initialize(user)\n")
        end
        user_model_file =  'app/models/user.rb'
        if File.exists?(user_model_file)
          insert_into_file user_model_file, "  has_many :filters, inverse_of: :user\n", :after => "class User < ActiveRecord::Base\n"
          insert_into_file user_model_file, "  has_many :export_templates, inverse_of: :user\n", :after => "class User < ActiveRecord::Base\n"
        end
      end


      #def show_readme
      #  readme "README" if behavior == :invoke
      #end

    private

      def copy_migrate(filename)
        if self.class.migration_exists?("db/migrate", "#{filename}")
          say_status("skipped", "Migration #{filename}.rb already exists")
        else
          migration_template "migrations/#{filename}.rb", "db/migrate/#{filename}.rb"
        end
      end

    end
  end
end
