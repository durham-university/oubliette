require 'rails_helper'

RSpec.describe "oubliette/preserved_files/index", type: :view do
  let!( :preserved_file ) { FactoryGirl.create(:preserved_file, :with_file) }
  let!( :preserved_file2 ) { FactoryGirl.create(:preserved_file, :with_file) }
  before do
    assign(:resources,Oubliette::PreservedFilesController.resources_for_page(1))
  end

  helper( Oubliette::ApplicationHelper )

  let(:page) { Capybara::Node::Simple.new(rendered) }

  let(:user) { FactoryGirl.create(:user,:admin) }
  before { sign_in user }

  it "renders a list of resources" do
    render
    expect(page).to have_selector("a[href='#{oubliette.preserved_file_path(preserved_file)}']")
    expect(page).to have_selector("a[href='#{oubliette.preserved_file_path(preserved_file2)}']")
  end
end
