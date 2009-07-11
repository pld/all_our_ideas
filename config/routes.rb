ActionController::Routing::Routes.draw do |map|
  map.login '/login', :controller => 'home', :action => 'login'
  map.logout '/logout', :controller => 'home', :action => 'logout'
  map.about '/about', :controller => 'home', :action => 'about'
  map.privacy '/privacy', :controller => 'home', :action => 'privacy'
  map.tour '/tour', :controller => 'home', :action => 'tour'
  map.forgot_password '/forgot_password', :controller => 'home', :action => 'forgot_password'
  map.resources :items, :collection => {
    :search => [:get, :post],
    :newest => [:get, :post],
    :all => [:get, :post],
    :score => [:get, :post],
    :activate => [:get, :post]
  }
  map.resources :questions, :member => { :state => :get, :export => :get }
  map.resources :users
  map.resources :vote, :collection => { :map => :get, :feedback => :get }
  map.namespace :admin do |admin|
    admin.resources :items, :member => { :state => :get }
  end
  map.root :controller => 'home', :action => 'index'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect ':name/:controller/:action/:id'
  map.connect '*path', :controller => 'vote', :action => 'named'
end
