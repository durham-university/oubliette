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

  post '/preserved_files/:id/select', to: 'preserved_files#select_resource', as: :select_preserved_file
  post '/preserved_files/:id/deselect', to: 'preserved_files#deselect_resource', as: :deselect_preserved_file
  post '/preserved_files/deselect_all', to: 'preserved_files#deselect_all_resources'
  post '/preserved_files/:id/deselect_all', to: 'preserved_files#deselect_all_resources', as: :deselect_all_preserved_file

  post '/file_batches/:id/move_into', to: 'file_batches#move_selection_into', as: :move_into_file_batch
  
  resources :background_job_containers, as: :durham_rails_background_job_containers
  get '/background_job_containers/:resource_id/background_jobs', to: 'background_jobs#index', as: :durham_rails_background_job_container_background_jobs
  resources :background_jobs, only: [:show]
  post '/background_job_containers/start_fixity_job', to: 'background_job_containers#start_fixity_job', as: :start_fixity_job
  post '/background_job_containers/start_export_job', to: 'background_job_containers#start_export_job', as: :start_export_job
  
end
