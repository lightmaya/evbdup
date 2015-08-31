Evbdup::Application.routes.draw do

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
   #root 'home#index'
  root :to => 'home#index'
  
  captcha_route

  get 'errors' => 'errors#index'
  get 'main' => 'kobe/main#index'

  resources :home, :only => :index  do 
    collection do
      get :form_test, :ajax_test, :test, :json_test
      post :form_test
    end
  end

  resources :uploads, :only => [:index, :create, :destroy]

  resources :users, :except => :show  do
    collection do
      get :sign_in, :sign_up, :sign_out, :forgot_password
      post :login, :create_user_dep, :valid_dep_name, :valid_user_login, :valid_captcha, :valid_user
    end
  end

  resources :sessions, :only => [:new, :create, :destroy]

# 后台begin
  namespace :kobe do
    resources :shared, :only => :index do
      collection do
        post :get_ztree_title, :ztree_json, :audit_next_user, :ajax_submit, :ajax_remove, :category_ztree_json
      end
    end
    resources :orders do
      collection do
        get :audit_ddcg, :ddcg_list
        post :same_template
      end
      member do
        get :audit, :print
        post :commit, :update_audit
      end
    end
    resources :departments do 
      collection do
        get :search, :list
        post :move, :valid_dep_name, :search_bank
      end
      member do 
        get :ztree, :add_user, :freeze, :upload, :delete, :recover, :show_bank, :audit
        post :update_add_user, :update_freeze, :update_upload, :commit, :update_recover, :edit_bank, :update_bank, :update_audit
      end
    end
    resources :articles do 
      collection do
        post :batch_task
      end
    end
    resources :menus do
      collection do
        get :ztree
        post :move
      end
      member do 
        get :delete
      end
    end
    resources :contract_templates do
      member do 
        get :delete
      end
    end
    resources :to_do_lists do
      member do 
        get :delete
      end
    end
    resources :rules do
      member do 
        get :delete, :audit_reason
      end
    end
    resources :users do 
      member do
        get :reset_password, :freeze, :recover, :only_show_info, :only_show_logs
        post :update_reset_password, :update_freeze, :update_recover
      end
    end
    resources :categories do
      collection do
        get :ztree
        post :move, :valid_name
      end
      member do 
        get :freeze, :delete, :recover
        post :update_freeze, :update_recover
      end
    end
    resources :products do
      collection do
        post :delete, :freeze, :recover
      end
    end
    # 意见反馈
    resources :suggestions do
      post :mark_as_read, :mark_as_unread, on: :member
      collection do
        get :list
        post :batch_opt, :create_upload
        delete :destroy_upload
      end
    end
  end
# 后台end

  resources :kobe, :only => :index do
    collection do
      get :search, :obj_class_json
    end
  end

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
