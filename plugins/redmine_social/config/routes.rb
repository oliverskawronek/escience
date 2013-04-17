RedmineApp::Application.routes.draw do
  

# automatic insertion for ads model
  resources :ads
# automatic insertion for friendship model
    get '/friendships.xml' => 'friendships#index', :as => :friendships_xml, :format => 'xml'
    get '/friendships' => 'friendships#index', :as => :friendships
	
    get 'manage_photos' => 'photos#manage_photos', :as => :manage_photos
    post 'create_photo.js' => 'photos#create', :as => :create_photo, :format => 'js'

    resources :users do
      member do 
        get 'statistics'
        get 'crop_profile_photo'
        put 'crop_profile_photo'
        get 'upload_profile_photo'
        put 'upload_profile_photo'
      end
      resources :friendships do
        collection do
          get :accepted
          get :pending
          get :denied
          get :write_message
        end
        member do
          put :accept
          put :deny
        end
      end
      resources :photos do
        get 'page/:page', :action => :index, :on => :collection
      end
	  resources :albums do
		resources :photos do
		  collection do
		    post :swfupload
		    get :slideshow
		  end
		end
	  end
    end
end