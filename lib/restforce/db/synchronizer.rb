module Restforce

  module DB

    # Restforce::DB::Synchronizer is responsible for synchronizing the records
    # in Salesforce with the records in the database. It relies on the mappings
    # configured in instances of Restforce::DB::RecordTypes::Base to create and
    # update records with the appropriate values.
    class Synchronizer

      # Public: Initialize a new Restforce::DB::Synchronizer.
      #
      # mapping - A Restforce::DB::Mapping.
      def initialize(mapping)
        @mapping  = mapping
        @strategy = mapping.strategy
      end

      # Public: Synchronize records for the current mapping from a Hash of
      # record descriptors to attributes.
      #
      # NOTE: Synchronizer assumes that the propagation step has done its job
      # correctly. If we can't locate a database record for a specific Salsforce
      # ID, we assume it shouldn't be synchronized.
      #
      # changes - A Hash, with keys composed of a Salesforce ID and model name,
      #           with Restforce::DB::Accumulator objects as values.
      #
      # Returns nothing.
      def run(changes)
        changes.each do |(id, salesforce_model), accumulator|
          next unless salesforce_model == @mapping.salesforce_model

          database_instance = @mapping.database_record_type.find(id)
          salesforce_instance = @mapping.salesforce_record_type.find(id)
          next unless database_instance && salesforce_instance

          update(database_instance, accumulator)   if @strategy.to_database?
          update(salesforce_instance, accumulator) if @strategy.to_salesforce?
        end
      end

      private

      # Internal: Update the passed instance with the accumulated attributes
      # from a synchronization run.
      #
      # instance    - An instance of Restforce::DB::Instances::Base.
      # accumulator - A Restforce::DB::Accumulator.
      #
      # Returns nothing.
      def update(instance, accumulator)
        diff = accumulator.diff(@mapping.convert(@mapping.salesforce_model, instance.attributes))
        attributes = @mapping.convert_from_salesforce(instance.record_type, diff)

        instance.update!(attributes)
      end

    end

  end

end
