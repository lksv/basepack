Lepidlo
=======

This project rocks and uses LGPL-LICENSE.

Generator usuage
================

1. ```rails new MyApp```
2. add to the ```Gemfile```:

```ruby
### Lepidlo
gem "lepidlo",      git: "https://github.com/lksv/lepidlo.git"
gem 'inherited_resources',  '~> 1.4.1'
gem 'ransack',              '~> 1.0'
gem 'kaminari'
gem "simple_form",          '~> 3.0.0.rc'
gem 'settingslogic'
gem "twitter-bootstrap-rails"
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
