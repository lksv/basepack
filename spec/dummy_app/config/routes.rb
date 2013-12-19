Dummy::Application.routes.draw do
  devise_for :users

  concern :resourcable do
    get    'options',     :on => :collection
    get    'query',       :on => :collection
    post   'query',       :on => :collection
    get    'export',      :on => :collection
    post   'export',      :on => :collection
    get    'import',      :on => :collection
    post   'import',      :on => :collection
    patch  'import',      :on => :collection
    delete 'import',      :on => :collection
    delete 'bulk_delete', :on => :collection

    get    'taggings',    :on => :collection
    get    'filters',     :on => :collection

    get    'diff',        :on => :member
    post   'merge',       :on => :member

    get    'bulk_edit',   on: :collection
    patch  'bulk_update', on: :collection
    post   'bulk_update', on: :collection

  end

  resources :employees, :projects, :tasks, :positions, :skills, :accounts,
    :employee_with_nesteds, :users, concerns: [:resourcable]

  root 'employees#index'
end
