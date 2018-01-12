Oubliette::Engine.routes.draw do
  root 'static_pages#home'

  get 'home' => 'static_pages#home'

  resources :file_batches do
    resources :preserved_files, only: [:new, :create]
  end
  get '/file_batches/:resource_id/channels', to: 'channels#index', as: :file_batch_channels
  
  resources :preserved_files
  get '/preserved_files/:id/download', to: 'downloads#show', as: :download

  get '/preserved_files/:resource_id/channels', to: 'channels#index', as: :preserved_file_channels
  post '/preserved_files/:resource_id/start_fixity_check', to: 'channels#call', as: :start_fixity_check_preserved_file, defaults: { binding_key: 'fixity_single' }
  post '/preserved_files/:resource_id/start_characterisation', to: 'channels#call', as: :start_characterisation_preserved_file, defaults: { binding_key: 'characterisation' }

  post '/preserved_files/:id/select', to: 'preserved_files#select_resource', as: :select_preserved_file
  post '/preserved_files/:id/deselect', to: 'preserved_files#deselect_resource', as: :deselect_preserved_file
  post '/preserved_files/deselect_all', to: 'preserved_files#deselect_all_resources'
  post '/preserved_files/:id/deselect_all', to: 'preserved_files#deselect_all_resources', as: :deselect_all_preserved_file

  post '/file_batches/:id/move_into', to: 'file_batches#move_selection_into', as: :move_into_file_batch
  
  resources :background_job_containers, as: :durham_rails_background_job_containers
  get '/background_job_containers/:resource_id/channels', to: 'channels#index', as: :durham_rails_background_job_container_channels
  post '/background_job_containers/start_fixity_job', to: 'channels#call', as: :start_fixity_job, defaults: { binding_key: 'fixity' }
  post '/background_job_containers/start_export_job', to: 'channels#call', as: :start_export_job, defaults: { binding_key: 'export' }
  
  Jobduct.draw_routes(self)
  
end
