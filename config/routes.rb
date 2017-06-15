Oubliette::Engine.routes.draw do
  root 'static_pages#home'

  get 'home' => 'static_pages#home'

  resources :file_batches do
    resources :preserved_files, only: [:new, :create]
  end

  resources :preserved_files
  get '/preserved_files/:id/download', to: 'downloads#show', as: :download

  get '/preserved_files/:resource_id/background_jobs', to: 'background_jobs#index', as: :preserved_file_background_jobs
  post '/preserved_files/:id/start_fixity_check', to: 'preserved_files#start_fixity_check', as: :start_fixity_check_preserved_file
  post '/preserved_files/:id/start_characterisation', to: 'preserved_files#start_characterisation', as: :start_characterisation_preserved_file
  
  resources :background_job_containers, as: :durham_rails_background_job_containers
  get '/background_job_containers/:resource_id/background_jobs', to: 'background_jobs#index', as: :durham_rails_background_job_container_background_jobs
  resources :background_jobs, only: [:show]
  post '/background_job_containers/start_fixity_job', to: 'background_job_containers#start_fixity_job', as: :start_fixity_job
  post '/background_job_containers/start_export_job', to: 'background_job_containers#start_export_job', as: :start_export_job
  
end
