Tonglian::Application.routes.draw do
  namespace :sys do
    resources :users do
      collection do
        post 'import_group_member'
      end
    end
    resources :groups do
      member do
        get 'invitation'
        post 'invite_users'
      end
      collection do
        delete 'destroy_user_group'
      end
    end
  end

  resources :weixins
  resources :feedbacks
  resources :sessions do
    collection do
      get "verification"
      post "verify"
      get "success"
      get "mail_verify"
    end
  end

  match '/step1' => 'sys/users#new'
  match '/step2' => 'sys/groups#new'
  match '/step3' => 'sys/groups#invitation'
  
  match "/login" => "sessions#new"
  match "/logout" => "sessions#destroy"
  root :to => 'sys/groups#index'
end
