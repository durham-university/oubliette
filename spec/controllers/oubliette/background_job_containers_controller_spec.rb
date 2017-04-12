require 'rails_helper'

RSpec.describe Oubliette::BackgroundJobContainersController, type: :controller do

  routes { Oubliette::Engine.routes }

  context "with admin user" do
    let(:user) { FactoryGirl.create(:user, :admin) }
    before { sign_in user }

    describe "POST #start_fixity_job" do
      it "starts the job" do
        expect(Oubliette.queue).to receive(:push).with(Oubliette::FixityJob) do |job|
          expect(job.file_limit).to be > 10
          expect(job.time_limit).to be > 2
        end
        post :start_fixity_job
      end
      it "sets params" do
        expect(Oubliette.queue).to receive(:push).with(Oubliette::FixityJob) do |job|
          expect(job.file_limit).to eql(10)
          expect(job.time_limit).to eql(2)
        end
        post :start_fixity_job, { file_limit: 10, time_limit: 2 }
      end
    end
  end
  
  context "with anonymous user" do
    describe "POST #start_fixity_job" do
      it "doesn't start the job" do
        expect(Oubliette.queue).not_to receive(:push)
        post :start_fixity_job
      end
    end
  end
end
