require 'rails_helper'

RSpec.describe Oubliette::FileBatchesController, type: :controller do

  let(:file_batch) { FactoryGirl.create(:file_batch) }
  let(:file_batch2) { FactoryGirl.create(:file_batch, title: 'moo test') }
  let(:preserved_file) { FactoryGirl.create(:preserved_file) }
  let(:file_batch_attributes) { FactoryGirl.attributes_for(:file_batch) }
  let(:invalid_attributes) { skip("Add tests for invalid attributes") }

  routes { Oubliette::Engine.routes }

  context "with an admin user" do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before { sign_in user }
    describe "GET #index" do
      it "assigns all file_batches and top level files as @resources" do
        file_batch ; file_batch2 ; preserved_file # create by refencing
        get :index
        expect(assigns(:resources).to_a).to match_array([file_batch, file_batch2, preserved_file])
      end

      describe "pagination" do
        let!( :many_batches ) {
          (1..25).map do |i|
            FactoryGirl.create(:file_batch, title: "Test batch #{i}", ingestion_date: DateTime.new(2015,1,1) + i.day)
          end
        }
        it "assigns a paging context" do
          get :index
          expect(assigns(:resources).current_page).to eql 1
          expect(assigns(:resources).total_pages).to eql 2
          expect(assigns(:resources).to_a.size).to eql 20
          expect(assigns(:resources).first.title).to eql "Test batch 25"
          expect(assigns(:resources).last.title).to eql "Test batch 6"
        end
        it "reads pagination parameters" do
          get :index, { page: 2, per_page: 10 }
          expect(assigns(:resources).current_page).to eql 2
          expect(assigns(:resources).total_pages).to eql 3
          expect(assigns(:resources).to_a.size).to eql 10
          expect(assigns(:resources).first.title).to eql "Test batch 15"
          expect(assigns(:resources).last.title).to eql "Test batch 6"
        end
      end
      
      describe "searching" do
        it "searches for batches" do
          file_batch ; file_batch2 # create by reference
          get :index, query: 'moo'
          expect(assigns(:resources).to_a.size).to eql 1
          expect(assigns(:resources).first.title).to eql "moo test"
        end
      end
    end

    describe "GET #show" do
      it "assigns the requested file batch as @resource" do
        get :show, {id: file_batch.to_param}
        expect(assigns(:resource)).to eq(file_batch)
      end
    end

    describe "GET #new" do
      it "assigns a new file batch as @resource" do
        get :new
        expect(assigns(:resource)).to be_a_new(Oubliette::FileBatch)
      end
    end

    describe "GET #edit" do
      it "assigns the requested file batch as @resource" do
        get :edit, {id: file_batch.to_param}
        expect(assigns(:resource)).to eq(file_batch)
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "creates a new FileBatch" do
          expect {
            post :create, {file_batch: file_batch_attributes}
          }.to change(Oubliette::FileBatch, :count).by(1)
        end
        
        it "saves all attributes" do
          post :create, {file_batch: file_batch_attributes}
          expect(assigns(:resource)).to be_a(Oubliette::FileBatch)
          expect(assigns(:resource).title).to eql(file_batch_attributes[:title])
          expect(assigns(:resource)).to be_persisted
        end

        it "redirects to the created preserved file" do
          post :create, {file_batch: file_batch_attributes}
          new_file_batch = Oubliette::FileBatch.all.to_a.find do |file_batch| file_batch.title == file_batch_attributes[:title] end
          expect(response).to redirect_to(new_file_batch)
        end
      end

      context "with invalid params" do
        it "assigns a newly created but unsaved preserved file as @resource" do
          post :create, {file_batch: invalid_attributes}
          expect(assigns(:resource)).to be_a_new(Oubliette::FileBatch)
        end

        it "re-renders the 'new' template" do
          post :create, {file_batch: invalid_attributes}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do

        it "updates the requested file batch" do
          expect(file_batch.title).not_to eql(file_batch_attributes[:title])
          put :update, {id: file_batch.to_param, file_batch: file_batch_attributes}
          file_batch.reload
          expect(file_batch.title).to eql(file_batch_attributes[:title])
        end

        it "assigns the requested file batch as @resource" do
          put :update, {id: file_batch.to_param, file_batch: file_batch_attributes}
          expect(assigns(:resource)).to eq(file_batch)
        end

        it "redirects to the file batch" do
          put :update, {id: file_batch.to_param, file_batch: file_batch_attributes}
          expect(response).to redirect_to(file_batch)
        end
      end

      context "with invalid params" do
        it "assigns the file batch as @resource" do
          put :update, {id: file_batch.to_param, file_batch: invalid_attributes}
          expect(assigns(:resource)).to eq(file_batch)
        end

        it "re-renders the 'edit' template" do
          put :update, {id: file_batch.to_param, repository: invalid_attributes}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested file batch" do
        file_batch # create by referencing
        expect {
          delete :destroy, {id: file_batch.to_param}
        }.to change(Oubliette::FileBatch, :count).by(-1)
      end

      it "doesn't destroy the preserved file if not allowed" do
        file_batch # create by referencing
        expect_any_instance_of(Oubliette::FileBatch).to receive(:allow_destroy?).and_return(false)
        expect {
          expect {
            delete :destroy, {id: file_batch.to_param}
          }.to raise_error('Not allowed to destroy this resource')
        }.not_to change(Oubliette::FileBatch, :count)
      end

      it "redirects to the file batch list" do
        delete :destroy, {id: file_batch.to_param}
        expect(response).to redirect_to(file_batches_url)
      end
    end
  end

  context "with anonymous user" do
    describe "POST #create" do
      it "fails authentication" do
        expect {
          post :create, {file_batch: file_batch_attributes}
        }.not_to change(Oubliette::FileBatch, :count)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
    describe "PUT #update" do
      it "fails authentication" do
        expect(file_batch.title).not_to eql(file_batch_attributes[:title])
        put :update, {id: file_batch.to_param, file_batch: file_batch_attributes}
        file_batch.reload
        expect(file_batch.title).not_to eql(file_batch_attributes[:title])
        expect(response).to redirect_to('/users/sign_in')
      end
    end
    describe "DELETE #destroy" do
      it "fails authentication" do
        file_batch # create by referencing
        expect {
          delete :destroy, {id: file_batch.to_param}
        }.not_to change(Oubliette::FileBatch, :count)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end
end
