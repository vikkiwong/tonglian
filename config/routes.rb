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
      post "send_verify_mail"
    end
  end
  root :to => 'sys/users#index'
end
