module Lepidlo
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)
      include ::Rails::Generators::Migration

      desc "Creates a Lepidlo initializer and copy locale files to your application."

      def add_assets
        js_manifest = 'app/assets/javascripts/application.js'
        if File.exist?(js_manifest)
          insert_into_file js_manifest, "//= require lepidlo\n", :after => "jquery_ujs\n"
        else
          copy_file "application.js", js_manifest
        end

        css_manifest = 'app/assets/stylesheets/application.css'
        scss_manifest = 'app/assets/stylesheets/application.css.scss'
        if File.exist?(css_manifest)
          content = File.read(css_manifest)
          insert_into_file css_manifest, " *= require lepidlo\n *= require lepidlo_and_overrides\n", :after => "require_self\n"
          copy_file "lepidlo_and_overrides.css", "app/assets/stylesheets/lepidlo_and_overrides.css"
        elsif File.exists?(scss_manifest)
          content = File.read(scss_manifest)
          append_file scss_manifest, '@import "lepidlo";'
          append_file scss_manifest, '@import "lepidlo_and_overrides";'
          copy_file "lepidlo_and_overrides.css", "app/assets/stylesheets/lepidlo_and_overrides.css"
        else
          copy_file "application.css.scss", "app/assets/stylesheets/application.css.scss"
        end
      end

      def check_cancan
        if !defined?(Devise) and yes?("Would you like to install CanCan?")
          gem 'cancan'
          generate "cancan:ability"
        end
      end

      def check_devise
        #othervise error: undefined local variable or method `current_user'
        if !defined?(CanCan) and yes?("Would you like to install Devise?")
          gem "devise"
          generate "devise:install"
          model_name = ask("What would you like the user model to be called? [user]")
          model_name = "user" if model_name.blank?
          generate "devise", model_name
        end
      end

      def copy_files
        template "lepidlo-settings.yml", "config/lepidlo-settings.yml"
        copy_file "../../../../config/locales/en.yml", "config/locales/lepidlo.en.yml"
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
  end

  #resources :lepidlo_example_resource, concerns: :resourcable
RUBY
        end
      end

      def rails_admin_init_script
        rails_admin_cfg_file = 'config/initializers/rails_admin.rb'
        if File.exist?(rails_admin_cfg_file)
          insert_into_file rails_admin_cfg_file, "  config.included_models = Lepidlo::Utils.detect_models #+ ['ActsAsTaggableOn::Tag', 'Delayed::Job']\n", :before => "end\n"
        else
          copy_file "rails_admin.rb", rails_admin_cfg_file
        end
      end

      #def show_readme
      #  readme "README" if behavior == :invoke
      #end
    end
  end
end
