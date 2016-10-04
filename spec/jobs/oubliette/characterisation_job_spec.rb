require 'rails_helper'

RSpec.describe Oubliette::CharacterisationJob do

  let(:file) { FactoryGirl.create(:preserved_file, :with_file) }

  let(:job) { Oubliette::CharacterisationJob.new(resource: file) }

  describe "marshalling" do
    let(:serial) { Marshal.dump(job) }
    let(:deserial) { Marshal.load(serial) }
    it "preserves resource" do
      expect(deserial.resource_id).to eql(file.id)
    end
  end

  describe "#run_job" do
    it "runs characterisation actor" do
      expect_any_instance_of(Oubliette::CharacterisationActor).to receive(:set_characterisation) do |actor|
        expect(actor.model_object.id).to eql(file.id)
      end
      job.run_job
    end
  end

end