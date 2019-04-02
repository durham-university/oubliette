Rails.application.routes.draw do
  root 'oubliette/static_pages#home'

  devise_for :users

  mount Oubliette::Engine => "/oubliette"

  resources :users, only: [:index, :show, :edit, :update, :destroy]

  if defined?(Oubliette::ResqueAdmin) && defined?(Resque::Server)
    namespace :admin do
      constraints Oubliette::ResqueAdmin do
        mount Resque::Server.new, at: 'queues'
      end
    end
  end  
end
