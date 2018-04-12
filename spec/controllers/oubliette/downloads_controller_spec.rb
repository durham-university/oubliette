require 'rails_helper'

RSpec.describe Oubliette::DownloadsController, type: :controller do

  let( :contents ) { fixture('test1.jpg').read }
  let( :preserved_file ) { FactoryGirl.create(:preserved_file,:with_file, access_groups: ['testgroup']) }
  let( :preserved_file2 ) { FactoryGirl.create(:preserved_file,:with_file, access_groups: ['othergroup']) }
  let( :preserved_file3 ) { FactoryGirl.create(:preserved_file,:with_file, access_groups: []) }
  
  routes { Oubliette::Engine.routes }

  let(:user) { FactoryGirl.create(:user, :admin) }
  before { sign_in user }

  describe "GET #show" do
    context "with admin user" do
      it "sends file contents" do
        get :show, {id: preserved_file.to_param}
        expect(response.body == contents).to eql true
      end
    end

    context "with regular user" do
      let(:user) { FactoryGirl.create(:user, roles: ['testgroup', 'editor']) }

      it "sends file if user in group" do
        get :show, {id: preserved_file.to_param}
        expect(response.body == contents).to eql true
      end

      it "doesn't send file if user not in the right group" do
        get :show, {id: preserved_file2.to_param}
        expect(response).to redirect_to(root_path)
      end

      it "doesn't send file if file has no group" do
        get :show, {id: preserved_file3.to_param}
        expect(response).to redirect_to(root_path)
      end
    end
  end

end
