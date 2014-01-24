Basepack
=======
[![Gem Version](https://badge.fury.io/rb/basepack.png)](http://badge.fury.io/rb/basepack)
[![Build Status](https://api.travis-ci.org/lksv/basepack.png?branch=master)](http://travis-ci.org/lksv/base_pack)
[![Dependency Status](https://gemnasium.com/lksv/basepack.png)](https://gemnasium.com/lksv/basepack)


By defining short configuration of how the standard pages (index, show,
edit, update) should look like (and behave) the library
can handls the controller actions and views for this pages. It
automatically handles all you need: sanitization, authentication (strong
parametes, cancan), view rendering and event REST API (for some of them).

Besides the standard pages (index, show, edit, ...) the library privides several other 
offten requested pages (forms) like: filer form, import and  export forms, bulk edit, 
merge, delete\_all.

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
* Support of a lot of bussiness type form fields like: date (datepicker), 
datetime, html5 wysiwig, tags, file upload and others. 
* support for dynamic form fields hiding depending on state of other fields as well 
as options of selectbox content modifications dependant on other fields.  


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

The generator will install several gems. Also, generator asks to delete 
`app/views/layouts/application.html.erb` because differend .haml version will be created.
If you don't know what to answer then answer 'yes' to generator's question.

In a bigger project do not forget to change ability in `app/models/ability.rb`. By
default, the generator adds ```can :manage, :all``` to enable anybody to perform any action on any object. 
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
* [RailsAdmin](https://github.com/sferik/rails_admin)
* ...[and others](basepack.gemspec)

Althoug you can use **Basepack** without knowing anything of the
background architecture it is recommended to get to know at least with:
[InheritedResources](https://github.com/josevalim/inherited_resources),
[CanCan](https://github.com/ryanb/cancan.git),
[Device](https://github.com/plataformatec/devise) and  
[RailsAdmin](https://github.com/sferik/rails_admin).


**Basepack** uses severral entities:
* Form - it is a class which is responsible to render page (partial) for
  the particular action.
  That means that the result of the Form should not be HTML \<form\> but any snippet of HTML.
  Basepack define
    * Edit Form - used for #new and #edit controller action
    * Show Form - used for #show controller action
    * List Form - used for #index controller action
    * Query Form - used when showing (modal) page with filter form.
    * Import Form - used on import page to select mapping of input files
      colloms to proper columns of model or associations.
    * Export Form - used on export page to select which model attributes
      (and association's models attributes) want to export.
    * Bulk Edit - form for change several fields at once (usually
      simillar to Edit Form, but fiels under N:M association should be
      added, deleted or exactly assigned).
    * Form Merge Form - used in action for merging two resource to one. 
      Allows you to choose which value of each attrite  should be used
      in the result object.

    Each form shoud take different input, for instance List form needs 
    know collection and what collumns to render (and other information). 
    Show form needs know resource and which fields it shoud show (and 
    how to show them).

    Notice that most of the Forms need to now which fields to show.

    Form should be instancinated by ```<form_name>_form_for``` controller's
    helper method. For example:
    ```
      show_form_for(Customer.first)
      edit_form_for(Customer.first)
      list_form_for(query_form)
    ```

* Session - (RailsAdmin Session is currently used for it.) 
  You can image Session as an particular configuration how the Form
  should behave. E.g. which Fields the Form should confist of.
  For instance, common requiremnt is to have different input form for
  new record and for editing record. Both of input forms shoud be
  rendered by Edit Form instance, once inicialized with Create Session
  and one with Edit Session. ([see definition of
  ```edit_form_for```](://github.com/lksv/basepack/blob/master/app/controllers/basepack/base_controller.rb#L374-L378))

  Session can handle other configuration for instance List form has
  property ```default_items_per_page``` to define how many items per
  page is shown (pagination is used).

  Session should also contains group of fields. E.g. seesion should be
  collection of group within a name and set of fields. 

  Basepack use following sessions:
    * Show (Show Form)
    * Edit (Edit Form)
    * Create (Edit Form)
    * BulkEdit (BulkEdit Form)
    * List (List Form)
    * TreeList (List Form)


* Field - (RailsAdmin Field is currenty used for it.) Represents any entity of 
  the model (it shoud be attribute, virtual attribute or association) and 
  futher information how to handle this entity:
    * how to render it
    * how to sanitize 
    * how to assing it (for instance, has many associations are set
      by "<association_name>_ids=" method.

**Basepack** was also
inspired by [RailsAdmin](https://github.com/sferik/rails_admin) and
still using [RailsAdmin
DSL](https://github.com/sferik/rails_admin/wiki/Railsadmin-DSL) for defining the forms, sessins and fields group.

## Future work ##
The main goal in the next major version is to separate form's DSL from
the model and put it more closely to the controller (probably to the
special directory app/forms/). This will leat to easy way how to define several 
forms of the same model as well as using different
forms depending on any particular data (like user's role).

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
