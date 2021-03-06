# -*- encoding : utf-8 -*-
Evbdup::Application.routes.draw do

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
   #root 'home#index'
   root :to => 'home#index'

  # captcha_route

  get 'errors' => 'errors#index'
  get 'help' => "home#help"
  get 'main' => 'kobe/main#index'
  get 'order_success' => 'home#order_success'
  get 'test' => 'errors#test'
  get 'not_found' => "home#not_found", as: :not_found
  get 'cart_order' => "kobe/orders#cart_order", as: :cart_order
  get "search", :to => 'home#search', :as => "search"
  get "more_list" => "home#more_list"
  get "dep_list" => "home#dep_list"
  get "mall" => "mall#index"

  get 'show_faqs' => "faqs#show"

  post 'check_ysd' => "home#check_ysd"

  # 检查是否登录
  get "check_login" => "home#check_login"
  resources  :transfers
  # 产品列表
  get 'channel/(:combo)' => "home#channel", :as => :channel

  post 'umeditor/file', :to => 'umeditor#file'
  post 'umeditor/image', :to => 'umeditor#image'
  get 'umeditor/image', :to => 'umeditor#image'

  # 购物车
  resource :cart, :controller => 'cart', :only => [:show, :destroy] do
    collection do
      get 'change/:id', :to => 'cart#change', :as => :change
      get 'dynamic', :to => 'cart#dynamic', :as => :dynamic
      delete 'rm/:id', :to => 'cart#rm', :as => :rm
    end
  end

  resources :departments, only: [:show]

  resources :products

  resources :mall, :only => :index do
    collection do
      get :redirect_to_dota
      post :get_token, :get_access_token, :create_order, :update_order, :send_sn
    end
  end

  resources :home, :only => :index  do
    collection do
      get :form_test, :ajax_test, :test, :json_test
      post :form_test
    end
  end

  resources :articles, :only => [:index, :show]

  resources :uploads, :only => [:index, :create, :destroy]

  resources :users, :except => :show  do
    collection do
      get :sign_in, :sign_up, :sign_out, :forgot_password
      post :login, :create_user_dep, :valid_dep_name, :valid_user_login, :valid_captcha, :valid_user
    end
  end

  resources :sessions, :only => [:new, :create, :destroy]

  resources :bid_projects

# 后台begin
namespace :kobe do
  resources :shared, :only => :index do
    collection do
      post :item_ztree_json, :get_ztree_title, :ztree_json, :audit_next_user, :ajax_submit, :ajax_remove, :category_ztree_json, :province_area_ztree_json, :department_ztree_json, :get_budgets_json, :user_ztree_json, :save_budget, :item_dep_json
      get :get_item_category, :get_budget_form
    end
  end

  resources :msgs do
    member do
      post :commit
    end
    collection do
      get :list
      get :read_msg
    end
  end

  resources :bargains do
    collection do
      get :list, :show_optional_category, :show_optional_products, :bid_list, :show_bid_details
      post :check_choose_dep
    end
    member do
      get :delete, :audit, :choose, :bid, :confirm
      post :commit, :update_audit, :update_choose, :update_bid, :update_confirm
    end
  end

  resources :bid_projects do
    collection do
      get :list
    end
    member do
      get :choose, :audit, :bid, :delete
      patch :update_choose
      post :commit, :update_audit
    end
  end

  resources :bid_project_bids do
    collection do
      get :bid
      post :update_bid
    end
  end

  resources :orders do
    collection do
      get  :my_list, :seller_list, :list, :grcg_list, :batch_audit
      post :same_template, :update_cart_order, :update_batch_audit
    end
    member do
      get :agent_confirm, :buyer_confirm, :audit, :print, :print_ht, :print_ysd, :invoice_number, :delete, :rating, :cancel
      post :commit, :update_audit, :update_agent_confirm, :update_buyer_confirm, :update_invoice_number, :update_rating, :update_cancel
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
      get :list
    end
    member do
      get :audit
      get :delete
      post :commit, :update_audit
    end
  end
  resources :article_catalogs do
    collection do
      get :ztree
      post :move
    end
    member do
      get :delete
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
  resources :items do
    collection do
      get :list, :classify
      post :update_classify
    end
    member do
      get :delete, :pause, :recover
      post :commit, :update_pause, :update_recover
    end
  end
  resources :plan_items do
    collection do
      # get :list
      post :dep_ztree_json
    end
    member do
      get :result_dep
      post :update_result_dep
    end
  end
  resources :plans do
    collection do
      get :show_item_category, :show_order_item_category, :list, :order_list, :order
      post :update_order, :bid_dep_ztree_json
    end
    member do
      get :delete, :audit
      post :commit, :update_audit
    end
  end

  resources :budgets do
    # collection do
    #   get :list
    # end
    # member do
    #   get :delete, :audit
    #   post :commit, :update_audit
    # end
  end

  resources :daily_costs do
    collection do
      get :list
    end
    member do
      get :delete, :audit
      post :commit, :update_audit
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
  resources :daily_categories do
    collection do
      get :ztree
      post :move, :valid_name
    end
    member do
      get :delete
    end
  end

  resources :fixed_assets do
    member do
      get :delete
    end
    collection do
      get  :get_category
     end
  end

  resources :asset_projects do
    collection do
      get :list
      post :get_fixed_asset_json
    end
    member do
      get :delete, :audit
      post :commit, :update_audit
    end
  end

  resources :tongji, only: :index do
     collection do
       get :item_dep_sales
     end
  end

   resources :faqs do
     member do
       get :delete ,:reply
       post :commit, :update_reply
     end
     collection do
      get  :get_catalog,:yjjy_list
     end

   end

   resources :transfers do
     member do
       get :delete
       post :commit
     end
   end

   resources :products do
      collection do
        get :item_list, :list, :batch_audit
        post :update_batch_audit
      end
      member do
        get :freeze, :delete, :recover, :audit
        post :commit, :update_freeze, :update_recover, :update_audit
      end
    end
    resources :agents do
      collection do
        get :list, :search_dep_name
      end
      member do
        get :delete
      end
    end
    # 总协调人
    resources :coordinators do
      collection do
        get :list
      end
      member do
        get :delete
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
