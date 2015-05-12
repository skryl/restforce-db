require "yaml"

module Restforce

  module DB

    # Restforce::DB::Configuration exposes a handful of straightforward write
    # and read methods to allow users to configure Restforce::DB.
    class Configuration

      attr_accessor(*%i(
        username
        password
        security_token
        client_id
        client_secret
        host
      ))

      # Public: Parse a supplied YAML file for a set of credentials, and use
      # them to populate the attributes on this configuraton object.
      #
      # file_path - A String or Path referencing a client configuration file.
      #
      # Returns nothing.
      def parse(obj)
        case obj
        when Hash
          load(obj)
        when String
          settings = YAML.load_file(file_path)
          load(settings["client"])
        end
      end

      # Public: Populate this configuration object from a Hash of credentials.
      #
      # configurations - A Hash of credentials, with keys matching the names
      #                  of the attributes for this class.
      #
      # Returns nothing.
      def load(configurations)
        self.username       = parsed(configurations, "username")
        self.password       = parsed(configurations, "password")
        self.security_token = parsed(configurations, "security_token")
        self.client_id      = parsed(configurations, "client_id")
        self.client_secret  = parsed(configurations, "client_secret")
        self.host           = parsed(configurations, "host")
      end

      private

      # Internal: Get the requested setting from a Hash of configurations.
      #
      # configurations - A Hash of configurations.
      # setting        - A String name of a single configuration in the Hash.
      #
      # Returns the value of the setting.
      # Raises ArgumentError if the setting is not contained in the Hash.
      def parsed(configurations, setting)
        configurations.fetch setting do |key|
          raise ArgumentError, "Configuration is missing #{key}"
        end
      end

    end

  end

end
