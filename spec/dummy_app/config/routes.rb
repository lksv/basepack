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

    get    'taggings',    :on => :collection
    get    'filters',     :on => :collection

    get    'diff',        :on => :member
    post   'merge',       :on => :member
  end

  resources :employees, :tasks, :positions, concerns: [:resourcable]
  resources :users, concerns: [:resourcable]

end
