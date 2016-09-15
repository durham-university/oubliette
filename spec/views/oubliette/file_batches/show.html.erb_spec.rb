require 'rails_helper'

RSpec.describe "oubliette/file_batches/show", type: :view do
  let( :file_batch ) { FactoryGirl.create(:file_batch, :with_files) }
  before do
    assign(:resource, file_batch)
    assign(:presenter, Oubliette::FileBatchesController.presenter_class.new(file_batch))
    controller.request.path_parameters[:id] = file_batch.id
  end

  helper( Oubliette::ApplicationHelper )

  let(:page) { Capybara::Node::Simple.new(rendered) }

  let(:user) { FactoryGirl.create(:user,:admin) }
  before { sign_in user }

  it "renders attributes in" do
    render
    expect(rendered).to include(file_batch.title)
    expect(page).to have_selector("a[href='#{oubliette.preserved_file_path(file_batch.files.first)}']")
  end
end
