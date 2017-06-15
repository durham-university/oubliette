require "rails_helper"

RSpec.describe Oubliette::PreservedFilesController, type: :routing do
  describe "routing" do
    routes { Oubliette::Engine.routes }

    it "routes to #index" do
      expect(get: "/preserved_files").to route_to("oubliette/preserved_files#index")
    end

    it "routes to #new" do
      expect(get: "/preserved_files/new").to route_to("oubliette/preserved_files#new")
    end
    
    it "routes to #new with batch" do
      expect(get: "/file_batches/1/preserved_files/new").to route_to("oubliette/preserved_files#new", file_batch_id: '1')
    end

    it "routes to #show" do
      expect(get: "/preserved_files/1").to route_to("oubliette/preserved_files#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/preserved_files/1/edit").to route_to("oubliette/preserved_files#edit", id: "1")
    end

    it "routes to #create" do
      expect(post: "/preserved_files").to route_to("oubliette/preserved_files#create")
    end
    
    it "routes to #create with batch" do
      expect(post: "/file_batches/1/preserved_files").to route_to("oubliette/preserved_files#create", file_batch_id: '1')
    end

    it "routes to #update via PUT" do
      expect(put: "/preserved_files/1").to route_to("oubliette/preserved_files#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/preserved_files/1").to route_to("oubliette/preserved_files#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/preserved_files/1").to route_to("oubliette/preserved_files#destroy", id: "1")
    end
    
    it "routes to #start_fixity_check" do
      expect(post: "/preserved_files/1/start_fixity_check").to route_to("oubliette/preserved_files#start_fixity_check", id: "1")
    end
    
    it "routes to #start_characterisation" do
      expect(post: "/preserved_files/1/start_characterisation").to route_to("oubliette/preserved_files#start_characterisation", id: "1")
    end

  end
end
