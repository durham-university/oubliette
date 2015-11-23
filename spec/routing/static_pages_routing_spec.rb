require "rails_helper"

RSpec.describe Oubliette::StaticPagesController, type: :routing do
  routes { Oubliette::Engine.routes }

  describe "root" do
    it "routes to #home" do
      expect(get: "/").to route_to("oubliette/static_pages#home")
    end
  end

  describe "routing" do
    it "routes to #home" do
      expect(get: "/home").to route_to("oubliette/static_pages#home")
    end
  end
end
