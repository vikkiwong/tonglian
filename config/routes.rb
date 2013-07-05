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
  resources :weixins
  resources :sessions do
    collection do
      get "verification"
      post "verify"
      get "success"
      get "mail_verify"
    end
  end
  match "/login" => "sessions#new"
  match "/logout" => "sessions#destroy"
  root :to => 'sys/users#index'
end
