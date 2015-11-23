require 'rails_helper'

RSpec.describe Oubliette::DownloadsController, type: :controller do

  let( :contents ) { fixture('test1.jpg').read }
  let( :preserved_file ) { FactoryGirl.create(:preserved_file,:with_file) }

  routes { Oubliette::Engine.routes }

  let(:user) { FactoryGirl.create(:user, :admin) }
  before { sign_in user }

  describe "GET #show" do
    it "sends file contents" do
      get :show, {id: preserved_file.to_param}
      expect(response.body == contents).to eql true
    end
  end

end
