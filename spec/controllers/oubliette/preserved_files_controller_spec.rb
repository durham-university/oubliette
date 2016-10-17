require 'rails_helper'

RSpec.describe Oubliette::PreservedFilesController, type: :controller do

  let(:preserved_file) { FactoryGirl.create(:preserved_file) }
  let(:preserved_file_attributes) { FactoryGirl.attributes_for(:preserved_file) }
  let(:invalid_attributes) { skip("Add tests for invalid attributes") }
  let(:uploaded_file) { fixture_file_upload('test1.jpg','image/jpeg') }

  routes { Oubliette::Engine.routes }

  context "with an admin user" do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before { sign_in user }
    describe "GET #index" do
      it "assigns all preserved files as @resources" do
        preserved_file # create by refencing
        get :index
        expect(assigns(:resources).to_a).to eq [preserved_file]
      end

      describe "pagination" do
        let!( :many_files ) {
          (1..25).map do |i|
            FactoryGirl.create(:preserved_file, title: "Test file #{i}", ingestion_date: DateTime.new(2015,1,1) + i.day)
          end
        }
        it "assigns a paging context" do
          get :index
          expect(assigns(:resources).current_page).to eql 1
          expect(assigns(:resources).total_pages).to eql 2
          expect(assigns(:resources).to_a.size).to eql 20
          expect(assigns(:resources).first.title).to eql "Test file 25"
          expect(assigns(:resources).last.title).to eql "Test file 6"
        end
        it "reads pagination parameters" do
          get :index, { page: 2, per_page: 10 }
          expect(assigns(:resources).current_page).to eql 2
          expect(assigns(:resources).total_pages).to eql 3
          expect(assigns(:resources).to_a.size).to eql 10
          expect(assigns(:resources).first.title).to eql "Test file 15"
          expect(assigns(:resources).last.title).to eql "Test file 6"
        end
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
        let(:preserved_file_attributes) { 
          FactoryGirl.attributes_for(:preserved_file, 
            ingestion_checksum: 'md5:15eb7a5c063f0c4cdda6a7310b536ba4',
            content: uploaded_file,
            content_type: 'image/jpeg' ) 
        }
        let(:file_batch) { FactoryGirl.create(:file_batch) }
        
        before {
          expect(Oubliette.queue).to receive(:push).with(Oubliette::CharacterisationJob)
        }
        
        it "creates a new PreservedFile" do
          expect {
            post :create, {preserved_file: preserved_file_attributes}
          }.to change(Oubliette::PreservedFile, :count).by(1)
        end
        
        it "creates a new PreservedFile inside a batch" do
          expect(file_batch.files.count).to eql(0)
          post :create, {preserved_file: preserved_file_attributes, file_batch_id: file_batch.id}
          file_batch.reload
          expect(file_batch.files.count).to eql(1)
          expect(file_batch.files.first.title).to eql(preserved_file_attributes[:title])
        end

        it "assigns a newly created preserved file as @resource" do
          post :create, {preserved_file: preserved_file_attributes}
          expect(assigns(:resource)).to be_a(Oubliette::PreservedFile)
          expect(assigns(:resource)).to be_persisted
        end
        
        it "saves all attributes" do
          post :create, {preserved_file: preserved_file_attributes}
          expect(assigns(:resource)).to be_a(Oubliette::PreservedFile)
          expect(assigns(:resource).title).to eql(preserved_file_attributes[:title])
          expect(assigns(:resource).ingestion_checksum).to eql(preserved_file_attributes[:ingestion_checksum])
          expect(assigns(:resource).content.original_name).to eql('test1.jpg')
          expect(assigns(:resource).content.mime_type).to eql('image/jpeg')
        end

        it "redirects to the created preserved file" do
          post :create, {preserved_file: preserved_file_attributes}
          new_preserved_file = Oubliette::PreservedFile.all.to_a.find do |preserved_file| preserved_file.title == preserved_file_attributes[:title] end
          expect(response).to redirect_to(new_preserved_file)
        end
        
        context "ingesting from path" do
          let(:file_path) { '/tmp/test/aaa.jpg' }
          let(:preserved_file_attributes) { 
            FactoryGirl.attributes_for(:preserved_file, 
              ingestion_checksum: 'md5:15eb7a5c063f0c4cdda6a7310b536ba4',
              content_path: file_path,
              content_type: 'image/jpeg' ) 
          }
          
          it "ingests from a path" do
            expect(controller).to receive(:resolve_content_path).with(file_path).and_return(uploaded_file)
            expect {
              post :create, {preserved_file: preserved_file_attributes}
            }.to change(Oubliette::PreservedFile, :count).by(1)            
          end
        end
      end

      
      context "with invalid params" do
        it "assigns a newly created but unsaved preserved file as @resource" do
          post :create, {preserved_file: invalid_attributes}
          expect(assigns(:resource)).to be_a_new(Oubliette::PreservedFile)
        end

        it "re-renders the 'new' template" do
          post :create, {preserved_file: invalid_attributes}
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
  
  describe "#resolve_content_path" do
    let(:file_path) { '/tmp/test/aaa.jpg' }
    
    it "returns file" do
      expect(Oubliette).to receive(:config).and_return({'ingestion_path' => '/tmp/test'})
      expect(File).to receive(:exists?).with(file_path).and_return(true)
      expect(File).to receive(:directory?).with(file_path).and_return(false)
      expect(File).to receive(:open).with(file_path,'rb').and_return(uploaded_file)
      expect(controller.send(:resolve_content_path,file_path)).to eql(uploaded_file)
    end
    
    it "doesn't return file if path ingestion is disabled" do
      expect(Oubliette).to receive(:config).and_return({})
      expect {
        controller.send(:resolve_content_path,file_path)
      }.to raise_error('Ingestion from disk not supported')
    end
    
    it "doesn't return file if path isn't under ingestion path" do
      expect(Oubliette).to receive(:config).and_return({'ingestion_path' => '/something'})
      expect {
        controller.send(:resolve_content_path,file_path)
      }.to raise_error("Not allowed to ingest from #{file_path}")
    end
  end
end
