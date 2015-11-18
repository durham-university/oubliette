Rails.application.routes.draw do
  root 'oubliette/preserved_files#index'

  mount Oubliette::Engine => "/oubliette"
end
