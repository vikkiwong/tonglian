Tonglian::Application.routes.draw do
  namespace :sys do
    resources :users do
      collection do
        get 'activate_group_manager'
        get 'send_activate_mail'
        get 'need_active'
        get 'active_mail_sended'
        get 'is_actived'
      end
    end
    resources :groups do
      member do
        get 'invitation'
        post 'invite_users'
      end
      collection do
        get 'create_group_user'
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
  
  match "/login" => "sessions#new"
  match "/logout" => "sessions#destroy"
  root :to => 'sys/groups#index'
end
