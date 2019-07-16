require 'rails_helper'
require 'jobduct/test/shared/channels_controller'

RSpec.describe Oubliette::ChannelsController, type: :controller do

  routes { Oubliette::Engine.routes }

  it_behaves_like "channels controller" do
    # One of the shared specs fails with user impersonation on, however
    # this is due to the way the spec is written than an actual bug. The spec
    # tries to spoof a user with user param which gets taken as user impersonation.
    before { allow(controller).to receive(:apply_impersonate) do end }

    let(:user) { FactoryBot.create(:user,:admin) }
    before { sign_in user }
  end

end