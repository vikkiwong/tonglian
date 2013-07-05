Tonglian::Application.routes.draw do
  namespace :sys do
    resources :users do
      collection do
        get 'multi_users'
        post 'import_users'
      end
    end
    resources :column_sets
  end

  root :to => 'sys/users#index'
end
