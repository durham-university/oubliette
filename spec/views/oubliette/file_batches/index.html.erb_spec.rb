require 'rails_helper'

RSpec.describe "oubliette/file_batches/index", type: :view do
  let!( :file_batch ) { FactoryGirl.create(:file_batch, :with_files) }
  let!( :preserved_file ) { FactoryGirl.create(:preserved_file, :with_file) }
  before do
    assign(:resources,Oubliette::FileBatchesController.index_resources)
  end

  helper( Oubliette::ApplicationHelper )

  let(:page) { Capybara::Node::Simple.new(rendered) }

  let(:user) { FactoryGirl.create(:user,:admin) }
  before { sign_in user }

  it "renders a list of resources" do
    render
    expect(page).to have_selector("a[href='#{oubliette.file_batch_path(file_batch)}']")
    expect(page).to have_selector("a[href='#{oubliette.preserved_file_path(preserved_file)}']")
  end
end
