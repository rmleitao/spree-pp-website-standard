Spree::Core::Engine.add_routes do
  resources :payment_notifications, :only => [:create]
end