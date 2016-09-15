require 'rails_helper'

RSpec.describe "oubliette/file_batches/edit", type: :view do
  let( :file_batch ) { FactoryGirl.create(:file_batch, :with_files) }
  before do
    assign(:resource, file_batch)
    assign(:form, Oubliette::FileBatchesController.edit_form_class.new(file_batch))
    controller.request.path_parameters[:id] = file_batch.id
  end

  helper( Oubliette::ApplicationHelper )

  let(:page) { Capybara::Node::Simple.new(rendered) }

  let(:user) { FactoryGirl.create(:user,:admin) }
  before { sign_in user }

  it "renders attributes in" do
    render
    assert_select "form[action=?][method=?]", oubliette.file_batch_path(file_batch), "post" do
    end
  end
end
