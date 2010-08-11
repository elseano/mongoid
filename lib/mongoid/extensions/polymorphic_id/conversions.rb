# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module PolymorphicID #:nodoc:
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        module ClassMethods #:nodoc
          
          def find(value)
            if value.is_a?(PolymorphicID)
              value.find
            else
              nil
            end
          end

          def set(value)
            if value.nil?
              nil
            else
              puts value.inspect
              { :type => value.class.name, :id => ::BSON::ObjectID(value.id.to_s) }
            end
          end

          def get(value)
            if value && value.respond_to?(:has_key?) && value.has_key?(:type) && value.has_key?(:id)
              new(value[:type], value[:id])
            else
              nil
            end
          end
        end
      end
    end
  end
end
