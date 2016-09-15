Oubliette::Engine.routes.draw do
  root 'static_pages#home'

  get 'home' => 'static_pages#home'

  resources :file_batches do
    resources :preserved_files, only: [:new, :create]
  end

  resources :preserved_files
  get '/preserved_files/:id/download', to: 'downloads#show', as: :download

  resources :background_job_containers, as: :durham_rails_background_job_containers
  get '/background_job_containers/:resource_id/background_jobs', to: 'background_jobs#index', as: :durham_rails_background_job_container_background_jobs
  resources :background_jobs, only: [:show]
  
end
