module Restforce

  module DB

    module RecordTypes

      # Restforce::DB::RecordTypes::ActiveRecord serves as a wrapper for a
      # single ActiveRecord::Base-compatible class, allowing for standard record
      # lookups and attribute mappings.
      class ActiveRecord < Base

        # Public: Create an instance of this ActiveRecord model for the passed
        # Salesforce instance.
        #
        # from_record - A Restforce::DB::Instances::Salesforce instance.
        #
        # Returns a Restforce::DB::Instances::ActiveRecord instance.
        # Raises on any validation or database error.
        def create!(from_record)
          record = @record_type.find_or_initialize_by(@mapping.lookup_column => from_record.id)
          record.assign_attributes(@mapping.convert(@record_type, from_record.attributes))
          associations = @mapping.associations.flat_map { |a| a.build(record, from_record.record) }

          record.transaction do
            record.save!
            # We touch the synchronization timestamps here to ensure that they
            # exceed the last updated timestamp.
            associations.each { |association| association.touch(:synchronized_at) }
          end

          instance_type.new(@record_type, record, @mapping).after_sync
        end

        # Public: Find the instance of this ActiveRecord model corresponding to
        # the passed salesforce_id.
        #
        # salesforce_id - The id of the record in Salesforce.
        #
        # Returns nil or a Restforce::DB::Instances::ActiveRecord instance.
        def find(id)
          record = @record_type.find_by(@mapping.lookup_column => id)
          return nil unless record

          instance_type.new(@record_type, record, @mapping)
        end

        # Public: Get a collection of all modified ActiveRecord records of this
        # type which match the passed criteria.
        #
        # options - A Hash of options which should be applied to the set of
        #           fetched records. Allowed options are:
        #           :before - A Time object defining the most recent update
        #                     timestamp for which records should be returned.
        #           :after  - A Time object defining the least recent update
        #                     timestamp for which records should be returned.
        #
        # Returns an Array of Restforce::DB::Instances::ActiveRecord instances.
        def all(options = {})
          scope = @record_type.where("updated_at > synchronized_at OR synchronized_at IS NULL")
          scope = scope.where("updated_at < ?", options[:before]) if options[:before]
          scope = scope.where("updated_at >= ?", options[:after]) if options[:after]

          scope.map do |record|
            instance_type.new(@record_type, record, @mapping)
          end
        end

        # Public: Destroy all database records corresponding to the list of
        # passed Salesforce IDs.
        #
        # ids - An Array of Salesforce IDs.
        #
        # Returns nothing.
        def destroy_all(ids)
          @record_type.where(@mapping.lookup_column => ids).destroy_all
        end

        # Public: Does the model represented by this record type have a column
        # with the requested name?
        #
        # column - A Symbol column name.
        #
        # Returns a Boolean.
        def column?(column)
          ::ActiveRecord::Base.connection.column_exists?(
            @record_type.table_name,
            column,
          )
        end

        private

        def instance_type
          Instances::ActiveRecord
        end

        # Internal: Has this Salesforce record already been linked to a database
        # record of this type?
        #
        # record - A Restforce::DB::Instances::Salesforce instance.
        #
        # Returns a Boolean.
        def synced?(record)
          @record_type.exists?(@mapping.lookup_column => record.id)
        end

      end

      class ActiveRecordLogged < ActiveRecord
        include Restforce::DB::RecordTypes::Logged

        def instance_type
          Instances::ActiveRecordLogged
        end
      end

    end

  end

end
