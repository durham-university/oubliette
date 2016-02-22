RSpec.shared_examples "model_common" do
  let( :json ) { {"id" => "5b/53/d8/08/5b53d808-2ab0-4966-85d2-7892fc033252","title" => "Test title"} }
  let( :json_s ) { json.to_json }
  let( :obj_class ) { described_class }
  let( :obj ) { obj_class.from_json(json) }

  describe "#from_json" do
    it "parses common json properties" do
      expect(obj.id).to eql '5b/53/d8/08/5b53d808-2ab0-4966-85d2-7892fc033252'
      expect(obj.title).to eql 'Test title'
    end
  end

  describe "#fetch" do
    it "returns self" do
      expect(obj.class).to receive(:get).and_return(OpenStruct.new(body: json_s, code: 200))
      expect(obj.fetch).to eq obj
    end
  end

  describe "#as_json" do
    it "adds attributes to json" do
      json = obj.as_json
      expect(json['id']).to eql '5b/53/d8/08/5b53d808-2ab0-4966-85d2-7892fc033252'
      expect(json['title']).to eql 'Test title'
    end
  end

  describe "#to_json" do
    it "works" do
      expect(obj.to_json).to be_a String
      expect(obj.to_json.length).to be > 0
    end
  end

  describe "::find" do
    it "fetches and returns a new object" do
      expect(obj_class).to receive(:get).and_return(OpenStruct.new(body: json_s, code: 200))
      new_obj = obj_class.find('5b/53/d8/08/5b53d808-2ab0-4966-85d2-7892fc033252')
      expect(new_obj).to be_a obj_class
      expect(new_obj.title).to eql 'Test title'
    end
    it "raises error when not found" do
      expect(obj_class).to receive(:get).and_return(OpenStruct.new(body: '', code: 404, message: 'Not found'))
      expect {
        obj_class.find('5b/53/d8/08/5b53d808-2ab0-4966-85d2-7892fc033252')
      }.to raise_error(Oubliette::API::FetchError)
    end
  end

  describe "::try_find" do
    it "finds the object when it exists" do
      expect(obj_class).to receive(:get).and_return(OpenStruct.new(body: json_s, code: 200))
      new_obj = obj_class.try_find('5b/53/d8/08/5b53d808-2ab0-4966-85d2-7892fc033252')
      expect(new_obj).to be_a obj_class
    end

    it "returns nil when the object doesn't exist" do
      expect(obj_class).to receive(:get).and_return(OpenStruct.new(body: '', code: 404, message: 'Not found'))
      new_obj = obj_class.try_find('5b/53/d8/08/5b53d808-2ab0-4966-85d2-7892fc033252')
      expect(new_obj).to be_nil
    end
  end
end
