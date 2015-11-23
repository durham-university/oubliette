Rails.application.routes.draw do
  root 'oubliette/static_pages#home'

  devise_for :users

  mount Oubliette::Engine => "/oubliette"
end
