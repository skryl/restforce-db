module Restforce

  module DB

    # Restforce::DB::AttributeMap encapsulates the logic for converting between
    # various representations of attribute hashes.
    class AttributeMap

      # DefaultAdapter defines the default data conversions between database and
      # Salesforce formats. It translates Dates and Times to ISO-8601 format for
      # storage in Salesforce.
      module DefaultAdapter

        # :nodoc:
        def self.to_database(value)
          value
        end

        # :nodoc:
        def self.to_salesforce(value)
          value = value.respond_to?(:utc) ? value.utc : value
          value.respond_to?(:iso8601) ? value.iso8601 : value
        end

      end

      # Public: Initialize a Restforce::DB::AttributeMap.
      #
      # database_model   - A Class compatible with ActiveRecord::Base.
      # salesforce_model - A String name of an object type in Salesforce.
      # fields           - A Hash of mappings between database columns and
      #                    fields in Salesforce.
      # conversions      - A Hash of mappings between database columns and the
      #                    corresponding adapter objects which should be used to
      #                    convert between data formats.
      def initialize(database_model, salesforce_model, fields = {}, conversions = {})
        @database_model = database_model
        @salesforce_model = salesforce_model
        @fields = fields
        @conversions = conversions

        @types = {
          database_model   => :database,
          salesforce_model => :salesforce,
        }
      end

      # Public: Build a normalized Hash of attributes from the appropriate set
      # of mappings. The keys of the resulting mapping Hash will correspond to
      # the database column names.
      #
      # from_format - A String or Class reflecting the record type from which
      #               the attribute Hash is being compiled.
      #
      # Yields a series of attribute names.
      # Returns a Hash.
      def attributes(from_format)
        case @types[from_format]
        when :salesforce
          @fields.each_with_object({}) do |(attribute, mapping), values|
            values[attribute] = adapter(attribute).to_database(yield(mapping))
          end
        when :database
          @fields.keys.each_with_object({}) do |attribute, values|
            values[attribute] = yield(attribute)
          end
        else
          raise ArgumentError
        end
      end

      # Public: Convert a Hash of normalized attributes to a format compatible
      # with a specific platform.
      #
      # to_format  - A String or Class reflecting the record type for which the
      #              attribute Hash is being compiled.
      # attributes - A Hash of attributes, with keys corresponding to the
      #              normalized attribute names.
      #
      # Examples
      #
      #   mapping = AttributeMap.new(
      #     MyClass,
      #     "Object__c",
      #     some_key: "SomeField__c",
      #   )
      #
      #   mapping.convert("Object__c", some_key: "some value")
      #   # => { "Some_Field__c" => "some value" }
      #
      #   mapping.convert(MyClass, some_key: "some other value")
      #   # => { some_key: "some other value" }
      #
      # Returns a Hash.
      def convert(to_format, attributes)
        case @types[to_format]
        when :database
          attributes.dup
        when :salesforce
          @fields.each_with_object({}) do |(attribute, mapping), converted|
            next unless attributes.key?(attribute)
            value = adapter(attribute).to_salesforce(attributes[attribute])
            converted[mapping] = value
          end
        else
          raise ArgumentError
        end
      end

      # Public: Convert a Hash of Salesforce attributes to a format compatible
      # with a specific platform.
      #
      # to_format  - A String or Class reflecting the record type for which the
      #              attribute Hash is being compiled.
      # attributes - A Hash of attributes, with keys corresponding to the
      #              Salesforce attribute names.
      #
      # Examples
      #
      #   map = AttributeMap.new(
      #     MyClass,
      #     "Object__c",
      #     some_key: "SomeField__c",
      #   )
      #
      #   map.convert_from_salesforce(
      #     "Object__c",
      #     "Some_Field__c" => "some value",
      #   )
      #   # => { "Some_Field__c" => "some value" }
      #
      #   map.convert_from_salesforce(
      #     MyClass,
      #     "Some_Field__c" => "some other value",
      #   )
      #   # => { some_key: "some other value" }
      #
      # Returns a Hash.
      def convert_from_salesforce(to_format, attributes)
        case @types[to_format]
        when :database
          @fields.each_with_object({}) do |(attribute, mapping), converted|
            next unless attributes.key?(mapping)
            value = adapter(attribute).to_database(attributes[mapping])
            converted[attribute] = value
          end
        when :salesforce
          attributes.dup
        else
          raise ArgumentError
        end
      end

      # Internal: Get the data format adapter for the passed attribute. Defaults
      # to DefaultAdapter if no adapter has been explicitly assigned for the
      # attribute.
      #
      # Returns an Object.
      def adapter(attribute)
        @conversions[attribute] || DefaultAdapter
      end

    end

  end

end
