= Lepidlo

This project rocks and uses LGPL-LICENSE.

= Generator usuage:

1. rails new MyApp
2. FIXME: change locale to :cs, othervise error: missing interpolation argument :entry\_name in "No %{entry\_name} found" ({:count=>0} given)
3. add Lepidlo's gems:

```ruby
### Lepidlo
gem "lepidlo",      git: "https://github.com/lksv/lepidlo.git"
gem 'inherited_resources'
gem 'ransack',      git: "https://github.com/ernie/ransack", branch: "rails-4"
gem 'kaminari',     git: "https://github.com/amatsuda/kaminari.git", ref: "03fe8ba9b04c85372e04b4e31e89060caee26ff" # fast total_count
gem "simple_form"  
gem 'settingslogic' 
gem 'bootbox-rails'
### /Lepidlo

```

4. bundle install
5. rails g lepidlo:install
6. remove from app/assets/stylesheets/application.css line: require\_tree .
7. define basic ability e.g. ```can :manage, :all```
8. rails g scaffold NAME [field[:type][:index] field[:type][:index]] [options]

FIXME:
 * route is generated above the concerns, which leads to the error
