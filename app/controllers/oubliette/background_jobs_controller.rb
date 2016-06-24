module Oubliette
  class BackgroundJobsController < Oubliette::ApplicationController
    include DurhamRails::BackgroundJobsControllerBehaviour
  end
end