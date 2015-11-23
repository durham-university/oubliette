require "rails_helper"

RSpec.describe Oubliette::DownloadsController, type: :routing do
  describe "routing" do
    routes { Oubliette::Engine.routes }

    it "routes to #show" do
      expect(:get => "/preserved_files/1/download").to route_to("oubliette/downloads#show", id: "1")
    end

  end
end
