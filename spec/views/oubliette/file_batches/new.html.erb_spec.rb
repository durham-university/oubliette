require 'rails_helper'

RSpec.describe "oubliette/file_batches/new", type: :view do
  let( :file_batch ) { FactoryGirl.build(:file_batch) }
  before do
    assign(:resource, file_batch)
    assign(:form, Oubliette::FileBatchesController.edit_form_class.new(file_batch))
  end

  helper( Oubliette::ApplicationHelper )

  let(:page) { Capybara::Node::Simple.new(rendered) }

  let(:user) { FactoryGirl.create(:user,:admin) }
  before { sign_in user }

  it "renders attributes in" do
    render
    assert_select "form[action=?][method=?]", oubliette.file_batches_path, "post" do
    end
  end
end
