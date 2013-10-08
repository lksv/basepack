class <%= controller_class_name %>Controller < ResourcesController
<% if options[:singleton] -%>
defaults :singleton => true
<% end -%>
  include Lepidlo::Import::Controller
end
