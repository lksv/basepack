= Lepidlo

This project rocks and uses LGPL-LICENSE.

= Generator usuage:

1. rails new MyApp
2. FIXME: change locale to :cs, othervise error: missing interpolation argument :entry\_name in "No %{entry\_name} found" ({:count=>0} given)
3. add Lepidlo's gems:

```ruby
### Lepidlo
gem "lepidlo",      path: "/home/lukas/projects/tst/lepidlo"
gem 'inherited_resources', git: 'https://github.com/jbecvar/inherited_resources.git', ref: 'dfa6ab95fdd26ea1c9152cf16f72a9a809963f01'
gem 'ransack',      git: "https://github.com/ernie/ransack", branch: "rails-4"
gem 'kaminari',     git: "https://github.com/amatsuda/kaminari.git", ref: "03fe8ba9b04c85372e04b4e31e89060caee26ff" # fast total_count
gem "simple_form",  git: 'https://github.com/plataformatec/simple_form.git', ref: '1ad1f9f895e69f91248fe96457bf6afa9bedb4dd'
gem 'settingslogic'  #FIXME: needs to be here, otherwise error at /home/lukas/projects/tst/lepidlo/app/views/lepidlo/base/_header.html.haml:25.
gem "twitter-bootstrap-rails", git: 'https://github.com/seyhunak/twitter-bootstrap-rails', ref: 'c26c235b8e16c62b53d8d14a9a6a367949155126'  #FIXME: needs to be here because of *nav-bar* helper which is used in _    navigation.html.erb
### /Lepidlo

```
4. bundle install
5. rails g lepidlo:install
6. remove from app/assets/stylesheets/application.css line: require\_tree .
7. define basic ability e.g. ```can :manage, :all```
8. TODO: not impllemented yet: ```rails g scaffold hruska``` which
   should:
 * add route with concerns
 * create 2 lines log controller
 * generate no views
