require "rails_helper"
require 'jobduct/test/shared/callbacks_routing'

RSpec.describe Oubliette::CallbacksController, type: :routing do
  routes { Oubliette::Engine.routes }

  it_behaves_like "callbacks routing"
end