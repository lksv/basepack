RailsAdmin.config do |config|
  # Label methods for model instances:
  config.label_methods = [:to_label, :name, :title] # Default is [:name, :title]
  config.authorize_with :cancan
end
