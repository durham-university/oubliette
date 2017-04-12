Oubliette::Engine.routes.draw do
  root 'static_pages#home'

  get 'home' => 'static_pages#home'

  resources :file_batches do
    resources :preserved_files, only: [:new, :create]
  end

  resources :preserved_files
  get '/preserved_files/:id/download', to: 'downloads#show', as: :download

  get '/preserved_files/:resource_id/background_jobs', to: 'background_jobs#index', as: :preserved_file_background_jobs
  
  resources :background_job_containers, as: :durham_rails_background_job_containers
  get '/background_job_containers/:resource_id/background_jobs', to: 'background_jobs#index', as: :durham_rails_background_job_container_background_jobs
  resources :background_jobs, only: [:show]
  post '/background_job_containers/start_fixity_job', to: 'background_job_containers#start_fixity_job', as: :start_fixity_job
  
end
