class <%= controller_class_name %>Controller < ResourcesController
<% if options[:singleton] -%>
defaults :singleton => true
<% end -%>
end
