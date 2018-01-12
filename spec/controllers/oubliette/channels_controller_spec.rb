require 'rails_helper'
require 'jobduct/test/shared/channels_controller'

RSpec.describe Oubliette::ChannelsController, type: :controller do

  routes { Oubliette::Engine.routes }

  it_behaves_like "channels controller" do
    let(:user) { FactoryBot.create(:user,:admin) }
    before { sign_in user }
  end

end