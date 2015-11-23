require 'rails_helper'

RSpec.describe User, type: :model do

  describe "is_admin?" do
    it "returns false for non-admin users" do
      expect( FactoryGirl.create(:user).is_admin? ).to eql false
    end

    it "returns true for admin users" do
      expect( FactoryGirl.create(:user,:admin).is_admin? ).to eql true
    end
  end

  describe "is_registered?" do
    it "returns false for new users users" do
      expect( User.new.is_registered? ).to eql false
    end

    it "returns true for other users" do
      expect( FactoryGirl.create(:user).is_registered? ).to eql true
    end
  end
end
