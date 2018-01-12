require "rails_helper"
require 'jobduct/test/shared/channels_routing'

RSpec.describe Oubliette::ChannelsController, type: :routing do
  routes { Oubliette::Engine.routes }

  it_behaves_like "channels routing"  
end
