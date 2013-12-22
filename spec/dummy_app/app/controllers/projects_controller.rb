class ProjectsController < ResourcesController
  include Basepack::Import::Controller

  def collection
    res = super().reorder('position')
    res.to_a
    res
  end

  def default_list_section
    :tree_list
  end
end
