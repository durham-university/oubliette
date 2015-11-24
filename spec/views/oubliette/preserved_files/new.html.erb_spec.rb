require 'rails_helper'

RSpec.describe "oubliette/preserved_files/new", type: :view do
  let( :preserved_file ) { FactoryGirl.create(:preserved_file, :with_file) }
  before do
    assign(:resource, preserved_file)
    assign(:form, Oubliette::PreservedFilesController.edit_form_class.new(preserved_file))
    controller.request.path_parameters[:id] = preserved_file.id
  end

  helper( Oubliette::ApplicationHelper )

  let(:page) { Capybara::Node::Simple.new(rendered) }

  let(:user) { FactoryGirl.create(:user,:admin) }
  before { sign_in user }

  it "renders attributes in" do
    render
    assert_select "form[action=?][method=?]", oubliette.preserved_file_path(preserved_file), "post" do
    end
  end
end
