= Lepidlo

This project rocks and uses LGPL-LICENSE.

= Generator usuage:

1. rails new MyApp
2. add Lepidlo's gems:

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

3. ```bundle install```
4. ```rails g lepidlo:install```
5. define basic ability e.g. ```can :manage, :all```
6. ```rails g scaffold NAME [field[:type][:index] field[:type][:index]] [options]```
7. ```rake db:migrate```
8. ```rails s```

FIXME:
 * route is generated above the concerns, which leads to the error
