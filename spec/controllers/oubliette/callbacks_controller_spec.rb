require 'rails_helper'
require 'jobduct/test/shared/callbacks_controller'

RSpec.describe Oubliette::CallbacksController, type: :controller do

  routes { Oubliette::Engine.routes }

  it_behaves_like "callbacks controller" do
    let(:user) { FactoryBot.create(:user,:admin) }
    before { sign_in user }
  end


end