module Restforce
  module DB
    module Instances
      module Logged

        def self.included(klass)
          klass.extend Forwardable
          klass.def_delegators :@mapping, :log
          klass.send(:include, InstanceMethods)
        end

        module InstanceMethods

          def update!(attributes)
            old_attributes = self.attributes
            super.tap do |record|
              log "    SUCCESS ~> #{target_name}: #{old_attributes.inspect}"
              log "      CHANGES: #{attributes.inspect}"
            end
          rescue => e
            log "    ERROR   ~> #{target_name}: #{old_attributes.inspect}"
            log "      CHANGES: #{attributes.inspect}"
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
