Oubliette::Engine.routes.draw do
  root 'static_pages#home'

  get 'home' => 'static_pages#home'

  resources :preserved_files
  get '/preserved_files/:id/download', to: 'downloads#show', as: :download

end
