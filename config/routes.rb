Tonglian::Application.routes.draw do
  namespace :sys do
    resources :users do
      collection do
        get  'bunch_new'
        post 'bunch_create'
        get  'group_new'
        post 'group_create'
        post 'import_group_member'
      end
    end
    resources :groups 
  end
  
  resources :weixins
  resources :feedbacks
  resources :sessions do
    collection do
      get "verification"
      post "verify"
      get "success"
      get "mail_verify"
      get 'apply_for_admin'
      post 'apply'
      get 'step_one'
      get 'step_two'
      get 'step_three'
      post 'create_group_manager'
    end
  end
  
  match "/login" => "sessions#new"
  match "/logout" => "sessions#destroy"
  root :to => 'sys/users#index'
end
