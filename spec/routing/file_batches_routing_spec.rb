require "rails_helper"

RSpec.describe Oubliette::FileBatchesController, type: :routing do
  describe "routing" do
    routes { Oubliette::Engine.routes }

    it "routes to #index" do
      expect(get: "/file_batches").to route_to("oubliette/file_batches#index")
    end

    it "routes to #new" do
      expect(get: "/file_batches/new").to route_to("oubliette/file_batches#new")
    end
    
    it "routes to #show" do
      expect(get: "/file_batches/1").to route_to("oubliette/file_batches#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/file_batches/1/edit").to route_to("oubliette/file_batches#edit", id: "1")
    end

    it "routes to #create" do
      expect(post: "/file_batches").to route_to("oubliette/file_batches#create")
    end
    
    it "routes to #update via PUT" do
      expect(put: "/file_batches/1").to route_to("oubliette/file_batches#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/file_batches/1").to route_to("oubliette/file_batches#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/file_batches/1").to route_to("oubliette/file_batches#destroy", id: "1")
    end

  end
end
