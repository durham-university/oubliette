require "rails_helper"

RSpec.describe Oubliette::BackgroundJobContainersController, type: :routing do
  describe "routing" do
    routes { Oubliette::Engine.routes }

    it "routes to #index" do
      expect(get: "/background_job_containers").to route_to("oubliette/background_job_containers#index")
    end

    it "routes to #new" do
      expect(get: "/background_job_containers/new").to route_to("oubliette/background_job_containers#new")
    end
    
    it "routes to #show" do
      expect(get: "/background_job_containers/1").to route_to("oubliette/background_job_containers#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/background_job_containers/1/edit").to route_to("oubliette/background_job_containers#edit", id: "1")
    end

    it "routes to #create" do
      expect(post: "/background_job_containers").to route_to("oubliette/background_job_containers#create")
    end
    
    it "routes to #update via PUT" do
      expect(put: "/background_job_containers/1").to route_to("oubliette/background_job_containers#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/background_job_containers/1").to route_to("oubliette/background_job_containers#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/background_job_containers/1").to route_to("oubliette/background_job_containers#destroy", id: "1")
    end
    
    it "routes to #start_fixity_job" do
      expect(post: "/background_job_containers/start_fixity_job").to route_to("oubliette/background_job_containers#start_fixity_job")
    end
    
    it "routes to #start_export_job" do
      expect(post: "/background_job_containers/start_export_job").to route_to("oubliette/background_job_containers#start_export_job")
    end

  end
end
