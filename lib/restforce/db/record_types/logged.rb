module Restforce
  module DB
    module RecordTypes
      module Logged

        def self.included(klass)
          klass.extend Forwardable
          klass.def_delegators :@mapping, :log
          klass.send(:include, InstanceMethods)
        end

        module InstanceMethods

          def create!(from_record)
            super.tap do |instance|
              log "    SUCCESS -> #{target_name}: #{instance.attributes.inspect}"
            end
          rescue => e
            log "    ERROR   -> #{target_name}: #{from_record.attributes.inspect}"
            log "      #{e}"
          end

          private

          def target_name
            self.class.name.split("::").last.gsub("Logged", '')
          end

        end #InstanceMethods
      end #Loggable
    end #Instances
  end #DB
end #Restforce
