require 'rails_helper'

RSpec.describe Oubliette::PreservedFilesController, type: :controller do

  let(:preserved_file) { FactoryGirl.create(:preserved_file) }
  let(:preserved_file_attributes) { FactoryGirl.attributes_for(:preserved_file) }
  let(:invalid_attributes) { skip("Add tests for invalid attributes") }

  routes { Oubliette::Engine.routes }

  describe "api debug" do
    context "api_debug not set in config" do
      it "fails authentication" do
        expect {
          post :create, {preserved_file: preserved_file_attributes, api_debug: 'true'}
        }.not_to change(Oubliette::PreservedFile, :count)
        expect(response).to redirect_to('/users/sign_in')
      end
    end

    context "api_debug is set in config" do
      before { Oubliette.config['api_debug'] = true }
      after { Oubliette.config.delete('api_debug') }
      it "lets in" do
        expect {
          post :create, {preserved_file: preserved_file_attributes, api_debug: 'true'}
        }.to change(Oubliette::PreservedFile, :count).by(1)
      end
    end
  end

  context "with an admin user" do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before { sign_in user }
    describe "GET #index" do
      it "assigns all preserved files as @repositories" do
        preserved_file # create by refencing
        get :index
        expect(assigns(:preserved_files)).to eq([preserved_file])
      end
    end

    describe "GET #show" do
      it "assigns the requested preserved file as @resource" do
        get :show, {id: preserved_file.to_param}
        expect(assigns(:resource)).to eq(preserved_file)
      end
    end

    describe "GET #new" do
      it "assigns a new preserved file as @resource" do
        get :new
        expect(assigns(:resource)).to be_a_new(Oubliette::PreservedFile)
      end
    end

    describe "GET #edit" do
      it "assigns the requested preserved file as @resource" do
        get :edit, {id: preserved_file.to_param}
        expect(assigns(:resource)).to eq(preserved_file)
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new PreservedFile" do
          expect {
            post :create, {preserved_file: preserved_file_attributes}
          }.to change(Oubliette::PreservedFile, :count).by(1)
        end

        it "assigns a newly created repository as @repository" do
          post :create, {preserved_file: preserved_file_attributes}
          expect(assigns(:resource)).to be_a(Oubliette::PreservedFile)
          expect(assigns(:resource)).to be_persisted
        end

        it "redirects to the created preserved file" do
          post :create, {preserved_file: preserved_file_attributes}
          new_preserved_file = Oubliette::PreservedFile.all.to_a.find do |preserved_file| preserved_file.title == preserved_file_attributes[:title] end
          expect(response).to redirect_to(new_preserved_file)
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved preserved file as @resource" do
          post :create, {preserved_file: invalid_attributes}
          expect(assigns(:resource)).to be_a_new(Schmit::Repository)
        end

        it "re-renders the 'new' template" do
          post :create, {repository: invalid_attributes}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do

        it "updates the requested preserved file" do
          expect(preserved_file.title).not_to eql(preserved_file_attributes[:title])
          put :update, {id: preserved_file.to_param, preserved_file: preserved_file_attributes}
          preserved_file.reload
          expect(preserved_file.title).to eql(preserved_file_attributes[:title])
        end

        it "assigns the requested preserved file as @resource" do
          put :update, {id: preserved_file.to_param, preserved_file: preserved_file_attributes}
          expect(assigns(:resource)).to eq(preserved_file)
        end

        it "redirects to the preserved file" do
          put :update, {id: preserved_file.to_param, preserved_file: preserved_file_attributes}
          expect(response).to redirect_to(preserved_file)
        end
      end

      context "with invalid params" do
        it "assigns the preserved file as @resource" do
          put :update, {id: preserved_file.to_param, preserved_file: invalid_attributes}
          expect(assigns(:resource)).to eq(preserved_file)
        end

        it "re-renders the 'edit' template" do
          put :update, {id: preserved_file.to_param, repository: invalid_attributes}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested preserved file" do
        preserved_file # create by referencing
        expect {
          delete :destroy, {id: preserved_file.to_param}
        }.to change(Oubliette::PreservedFile, :count).by(-1)
      end

      it "doesn't destroy the preserved file if not allowed" do
        preserved_file # create by referencing
        expect_any_instance_of(Oubliette::PreservedFile).to receive(:allow_destroy?).and_return(false)
        expect {
          expect {
            delete :destroy, {id: preserved_file.to_param}
          }.to raise_error('Not allowed to destroy this resource')
        }.not_to change(Oubliette::PreservedFile, :count)
      end

      it "redirects to the preserved files list" do
        delete :destroy, {id: preserved_file.to_param}
        expect(response).to redirect_to(preserved_files_url)
      end
    end
  end

  context "with anonymous user" do
    describe "POST #create" do
      it "fails authentication" do
        expect {
          post :create, {preserved_file: preserved_file_attributes}
        }.not_to change(Oubliette::PreservedFile, :count)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
    describe "PUT #update" do
      it "fails authentication" do
        expect(preserved_file.title).not_to eql(preserved_file_attributes[:title])
        put :update, {id: preserved_file.to_param, preserved_file: preserved_file_attributes}
        preserved_file.reload
        expect(preserved_file.title).not_to eql(preserved_file_attributes[:title])
        expect(response).to redirect_to('/users/sign_in')
      end
    end
    describe "DELETE #destroy" do
      it "fails authentication" do
        preserved_file # create by referencing
        expect {
          delete :destroy, {id: preserved_file.to_param}
        }.not_to change(Oubliette::PreservedFile, :count)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end
end
