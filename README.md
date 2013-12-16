Basepack
=======
[![Build Status](https://api.travis-ci.org/lksv/basepack.png?branch=master)](http://travis-ci.org/lksv/base_pack)

**Basepack** is a Ruby on Rails framework for fast creating of information
systems.

## Features

* Fast development of forms - generates forms for resource by short DSL metadata
  settings.
* Rich set of business types support (datetime, wysiwig, tags, phone number, ...)
* Search and filtering, saved filters
* Automatic form validation
* Import and Export functionality for resource
* Easy way to create custom actions
* Authentication (via [Devise](ttps://github.com/plataformatec/devise))
* Authorization (via [Cancan](https://github.com/ryanb/cancan.git))

## Documentation

TODO

## Demo

TODO:
* link to running demo (heroku?)
* link to github source

## Installation

In your `Gemfile`, add the following dependencies:

    gem "basepack",      git: "https://github.com/lksv/basepack.git"

Run:

    bundle install

And then run:

    rails g basepack:install

This generator will install **Basepack**, 
[Devise](https://github.com/plataformatec/devise) and
[CanCan](https://github.com/ryanb/cancan.git) and following gems
* inherited\_resources
* ransack
* kaminari
* simple\_form
* settingslogic
* twitter-bootstrap-rails
* bootbox-rails

if you don't already have them installed.

Define inital ability in `app/models/ability.rb`. You can put ```can
:manage, :all``` to enable anybody to perform any
action on any object. See more on [CanCan
wiki](https://github.com/ryanb/cancan/wiki/Defining-Abilities).

Migrate your database and start the server:

    rake db:migrate
    rails s


## Generator usage

You can easily generate new resource (scaffold for the resource) by
```rails g scaffold NAME [field[:type][:index] field[:type][:index]] [options]```.
E.g.

    rails g scaffold Project name short_description description:text start:date finish:date
    rails g scaffold Task name description:text project:references user:references

Then 
```rake db:migrate```
```rails s```

Notice that files for views are not generated (directories appp/views/projects and appp/views/tasks are empty), but all RESTful actions are working correctly. It is because views iherit default structure and you can easily override these defaults by creating appropriate files.

## Basic usage

After scaffolding your resources, you can customize fields used in individual actions by [Railsdmin DSL](https://github.com/sferik/rails_admin/wiki/Railsadmin-DSL)

File ```app/models/project.rb```:
```
class Project < ActiveRecord::Base
  has_many :tasks, inverse_of: :project
  validates :name, :short_description, presence: true

  rails_admin do
    list do
      field :name
      field :short_description
      field :finish
    end

    edit do
      field :name
      field :short_description
      field :description, :wysihtml5
      field :start
      field :finish
     end 

     show do
       field :name
       field :description
       field :start
       field :finish
     end 
  end 
end
```

File ```app/models/task.rb```
```
class Task < ActiveRecord::Base
  belongs_to :project, inverse_of: :tasks
  belongs_to :user
end
```
IMPORTANT! Make sure that you define inverse_of option on has_one, has_many and belongs_to associations. It is necessary for correct functioning of **Basepack**, see [Rails documentation](http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#label-Bi-directional+associations) for explaination.


Another difference is controllers which inherit from ResourcesController. Full inheritance hierarchy looks this way:
```
ProjectsController < ResourcesController < Basepack::BaseController < InheritedResources::Base
```


If you are not familiar with [InheritedResources](https://github.com/josevalim/inherited_resources), take a look at it.  

Basepack::BaseController adds to it:
* strong parameters handling
* ```options``` method
* ```taggings``` method
* ```build_resource``` method

You do NOT need to define permitted parameters anymore. It is defined by RailsAdmin DSL, more precisely by what you set as visible in edit action. 
So file ```app/models/project.rb```:

```
class Project < ActiveRecord::Base
  ...
    edit do
      field :name
      field :short_description
      field :description, :wysihtml5
      field :start
      field :finish
     end 
  ...
end
```

implicitly sets permitted params which could be written as:
```
def permitted_params
  params.permit(:project => [:name, :short_description, :description, :start, :finish])
end
```
in your projects controller. You can override these implicit settings by creating this method in case you want it.

## Basic Architecture Background

**Basepack** is build on the top of several gems:
* [Device](https://github.com/plataformatec/devise) for Authentication
* [CanCan](https://github.com/ryanb/cancan.git) for Authorization
* [InheritedResources](https://github.com/josevalim/inherited_resources)
   makes your controllers inherit all restful actions.
* [SimpleForm](https://github.com/plataformatec/simple_form) for
  creating Forms.
* [nested-form](https://github.com/ryanb/nested_form) for handling
  multiple models in a single form
* [bootstrap-sass](https://github.com/thomas-mcdonald/bootstrap-sass)
* ...[and others](basepack.gemspec)

Althoug you can use **Basepack** without knowing anything of the
background architecture it is recommended to get to know at least with:
[InheritedResources](https://github.com/josevalim/inherited_resources),
[CanCan](https://github.com/ryanb/cancan.git) and
[Device](https://github.com/plataformatec/devise). 

**Basepack** was also
inspired by [RailsAdmin](https://github.com/sferik/rails_admin) and
still using [RailsAdmin
DSL](https://github.com/sferik/rails_admin/wiki/Railsadmin-DSL) for defining the forms.

TODO - explain the concept. Class ```Basepack::Form::Base``` and ```Basepack::Form::Fields::Base```.
Controller action as ```<form_name>_form_for``` and ```form_factory_rails_admin```.

## Customining Views

## Customizing Form View

License
=======

This project rocks and uses LGPL-LICENSE.

Credits
=======

[RailsAdmin](https://github.com/sferik/rails_admin) field forms was
originaly taken from rails-admin.

[nested_form_ui](https://github.com/tb/nested_form_ui) - stylesheed and
code for orderable was inspired by this project.

## TODO
* Generator - set proprely model inherites form ResourcesController add
  include for imports
* Add support of tags and wysihtml5 out of the box
