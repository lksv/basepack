Basepack
=======
[![Gem Version](https://badge.fury.io/rb/basepack.png)](http://badge.fury.io/rb/basepack)
[![Build Status](https://api.travis-ci.org/lksv/basepack.png?branch=master)](http://travis-ci.org/lksv/base_pack)
[![Dependency Status](https://gemnasium.com/lksv/basepack.png)](https://gemnasium.com/lksv/basepack)

**Basepack** is a Ruby on Rails framework for quick creation of information
systems. 

**Basepack** dramatically helps you to start your new project.
There are out of the box form fields like: date (datepicker), datetime, html5
wysiwig, tags, file upload and others. Further more there is support for 
dynamic field hiding depending on state of other fields as well as
options of selectbox content modifications dependant on other fields.

**Basepack** contains a lot of predefined forms, views and actions which you might need
(filter form, bulk changes, delete\_all, import, export, ...).

## Features

* Quick development of forms - generates forms for resource by short DSL metadata
  settings.
* Rich set of business types support (datetime, wysiwig, tags, phone number, ...)
* Search and filtering, saved filters
* Automatic form validation
* Import and Export functionality for resource
* Easy way to create custom actions
* Security: permited parameters are automatically defined against fields in edit forms which are (read-write).
* Authentication (via [Devise](ttps://github.com/plataformatec/devise))
* Authorization (via [Cancan](https://github.com/ryanb/cancan.git))

All the field form definitions are done by [RailsAdmin](https://github.com/sferik/rails_admin) and are configured
accordingly.  It simplifies configuration process and if you wish to use
RailsAdmin as an admin interface.


## Documentation

[Tutorial](https://github.com/lksv/basepack/wiki/Tutorial)

See project [wiki](https://github.com/lksv/basepack/wiki).

## Demo

*Currently [zorec](https://github.com/zorec) is preparing 
[basepace_example application](https://github.com/zorec/basepack_example)*

The running application will be available at [http://basepack-example.herokuapp.com/](http://basepack-example.herokuapp.com/)

## Installation

In your `Gemfile`, add the following dependencies:

    gem "basepack"

Run:

    bundle install

And then run:

    rails g basepack:install

The generator asks you to install several gems. If you don't know what
to answer then answer 'yes' to all generator's questions

Do not forget to define ability in `app/models/ability.rb`. You can put ```can
:manage, :all``` to enable anybody to perform any action on any object. 
See more on [CanCan wiki](https://github.com/ryanb/cancan/wiki/Defining-Abilities).

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

Notice that:
1. Generated controllers inherits form ResourcesController.
2. Files for views are not generated (directories appp/views/projects 
and appp/views/tasks are empty), but all RESTful actions are working correctly. 
It is because views inherit default structure from controller inheritance) 
and you can easily override these defaults by creating appropriate files.

## Basic usage

After scaffolding your resources, you can customize fields used in individual actions by [Railsdmin DSL](https://github.com/sferik/rails_admin/wiki/Railsadmin-DSL)

File ```app/models/project.rb```:

```ruby
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
```ruby
class Task < ActiveRecord::Base
  belongs_to :project, inverse_of: :tasks
  belongs_to :user, inverse_of: :tasks
end
```

Add folowing line to ```app/models/user``` file:
```ruby
   has_many tasks, inverse_of: user
```

Pleas note that ```inverse_of``` option is included on association. It is 
necessary for correct functioning of **Basepack**, see 
[Rails documentation](http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#label-Bi-directional+associations) 
and [RailsAdmin
wiki](https://github.com/sferik/rails_admin/wiki/Associations-basics#inverse_of-avoiding-edit-association-spaghetti-issues) 
for explaination.


Almoust all the staff what Baseback do is through  Basepack::BaseController which inherit from ResourcesController. Full inheritance hierarchy looks this way:
```
ProjectsController < ResourcesController < Basepack::BaseController < InheritedResources::Base
```


If you are not familiar with [InheritedResources](https://github.com/josevalim/inherited_resources), take a look at it.  

You do NOT need to define permitted parameters anymore. It is defined by RailsAdmin DSL, more precisely by what you set as visible in edit action. 
So file ```app/models/project.rb```:

```ruby
class Project < ActiveRecord::Base
  #...
  rails_admin do
    #...
    edit do
      field :name
      field :short_description
      field :description, :wysihtml5
      field :start
      field :finish
     end 
   end
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
DSL](https://github.com/sferik/rails_admin/wiki/Railsadmin-DSL) for defining the forms, sessins and fields group.

License
=======

This project rocks and uses LGPL-LICENSE.

Credits
=======

[RailsAdmin](https://github.com/sferik/rails_admin) field views and some forms (export form) was
originaly taken from rails-admin.

[nested_form_ui](https://github.com/tb/nested_form_ui) - stylesheed and
code for orderable was inspired by this project.







[![Analytics](https://ga-beacon.appspot.com/UA-46491076-2/basepack/README.md?pixel)](https://github.com/igrigorik/ga-beacon)
