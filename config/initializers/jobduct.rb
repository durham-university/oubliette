# Add job consumers here, e.g.
# Jobduct::Binding.new(AddJob, 'add'),
Jobduct.bindings = [
  Jobduct::Binding.new(Oubliette::CharacterisationJob, 'characterisation'),
  Jobduct::Binding.new(Oubliette::ExportJob, 'export'),
  Jobduct::Binding.new(Oubliette::FixityJob, 'fixity'),
  Jobduct::Binding.new(Oubliette::SingleFixityJob, 'fixity_single'),
  Jobduct::Binding.new(Oubliette::IngestionJob, 'ingest_file'),
  Jobduct::Binding.new(Oubliette::BatchIngestionJob, 'ingest_batch'),
  Jobduct::Binding.new(Oubliette::CreateBatchJob, 'create_batch'),
  Jobduct::Binding.new(Oubliette::PostIngestionJob, 'post_ingestion')
]

# Change the runner adapter from ActiveJob to Rescue or something else if needed
Jobduct.runner_adapter = Jobduct::ResqueAdapter.new
