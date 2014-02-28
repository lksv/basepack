module TreeListHelper

  # Creates tree structure for collection
  # * +form+ - form renderer used for rendering resource actions
  # * +expanded+ - array of expanded nodes ids (integer)
  # * +nested_collection+ - collection of resources in actual tree level
  #
  # Returns array of hashes with nodes info for Fancytree
  # :key - string, mandatory, node id
  # :title - string, mandatory, displayed title of node
  # :folder - boolean, true if node has childrens/is expandable
  # :lazy - boolean, AJAX is used for children loading
  # :children - array of node children (used if node is expanded)
  def nested_tree_nodes(form, expanded, nested_collection = form.collection)
    nodes = []

    nested_collection.each_with_index do |res, i| 
      form.with_resource(res, res, i) do
        form.render_row do

          node = {
            # TODO: remove to_s for new fancytree build (issue 90)
            key: form.resource.id.to_s,
            title: form.resource.to_label
          }

          # create folder if node has children
          if form.resource.has_children?
            node[:folder] = true
            node[:lazy] = true

            # expand and load subtree if expanded before
            if expanded.include?(form.resource.id)
              node[:children] = nested_tree_nodes(form, expanded, 
                  form.resource.children)
              node[:lazy] = false
            end
          end

          node[:title] += content_tag :div, class: 'btn-group btn-mini' do
            form.render_actions
          end

          nodes << node

        end # row
      end # end form
    end # end collection

    nodes
  end

end
