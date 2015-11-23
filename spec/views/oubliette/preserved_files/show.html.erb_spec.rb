require 'rails_helper'

RSpec.describe "oubliette/preserved_files/show", type: :view do
  let( :preserved_file ) { FactoryGirl.create(:preserved_file, :with_file) }
  before do
    assign(:resource, preserved_file)
    controller.request.path_parameters[:id] = resource.id
  end

  helper( Oubliette::ApplicationHelper )

  let(:page) { Capybara::Node::Simple.new(rendered) }

  let(:user) { FactoryGirl.create(:user,:admin) }
  before { sign_in user }

  it "renders attributes in" do
    render
  end
end
