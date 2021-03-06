require_relative "../../../test_helper"

describe Restforce::DB::Model do

  configure!

  let(:database_model) { CustomObject }
  let(:salesforce_model) { "CustomObject__c" }

  before do
    database_model.send(:include, Restforce::DB::Model)
  end

  describe ".sync_with" do
    before do
      database_model.sync_with(salesforce_model) do
        maps(
          name:    "Name",
          example: "Example_Field__c",
        )
      end
    end

    it "adds a mapping to the global Restforce::DB::Registry" do
      expect(Restforce::DB::Registry[database_model]).to_not_be :empty?
    end
  end

end
