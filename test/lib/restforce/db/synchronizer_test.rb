require_relative "../../../test_helper"

describe Restforce::DB::Synchronizer do

  configure!
  mappings!

  let(:synchronizer) { Restforce::DB::Synchronizer.new(mapping) }

  describe "#run", vcr: { match_requests_on: [:method, VCR.request_matchers.uri_without_param(:q)] } do
    let(:attributes) do
      {
        name:    "Custom object",
        example: "Some sample text",
      }
    end
    let(:salesforce_id) do
      Salesforce.create!(
        salesforce_model,
        mapping.convert(salesforce_model, attributes),
      )
    end
    let(:changes) { { [salesforce_id, salesforce_model] => accumulator } }
    let(:new_attributes) do
      {
        "Name" => "Some new name",
        "Example_Field__c" => "New sample text",
      }
    end
    let(:accumulator) do
      Restforce::DB::Accumulator.new.tap do |accumulator|
        accumulator.store(Time.now, new_attributes)
      end
    end

    describe "given a Salesforce record with no associated database record" do
      before do
        salesforce_id
        synchronizer.run(changes)
      end

      it "does nothing for this specific mapping" do
        record = mapping.salesforce_record_type.find(salesforce_id)
        expect(record.attributes).to_equal attributes
      end
    end

    describe "given a Salesforce record with an associated database record" do
      let(:database_attributes) do
        {
          name:            "Some existing name",
          example:         "Some existing sample text",
          synchronized_at: Time.now,
        }
      end
      let(:database_record) do
        database_model.create!(database_attributes.merge(salesforce_id: salesforce_id))
      end

      before do
        database_record
        synchronizer.run(changes)
      end

      it "updates the database record" do
        record = database_record.reload

        expect(record.name).to_equal new_attributes["Name"]
        expect(record.example).to_equal new_attributes["Example_Field__c"]
      end

      it "updates the salesforce record" do
        record = mapping.salesforce_record_type.find(salesforce_id).record

        expect(record.Name).to_equal new_attributes["Name"]
        expect(record.Example_Field__c).to_equal new_attributes["Example_Field__c"]
      end
    end

  end
end
