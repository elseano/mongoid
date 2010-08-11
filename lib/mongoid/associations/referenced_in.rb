# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    # Represents a relational association to a "parent" object.
    class ReferencedIn < Proxy

      # Initializing a related association only requires looking up the object
      # by its id.
      #
      # Options:
      #
      # document: The +Document+ that contains the relationship.
      # options: The association +Options+.
      def initialize(document, options, target = nil)
        @options = options
        target ||= load_from(document)

        replace(target)
        extends(options)
      end

      # Replaces the target with a new object
      #
      # Returns the association proxy
      def replace(obj)
        @target = obj
        self
      end
      
      # Loads the document defined by the relationship
      def load_from(document)
        foreign_key = document.send(@options.foreign_key)
        return nil if foreign_key.blank?

        if foreign_key.is_a?(PolymorphicID)
          foreign_key.find
        else
          @options.klass.find(foreign_key)
        end
      end

      class << self
        # Returns the macro used to create the association.
        def macro
          :referenced_in
        end

        # Perform an update of the relationship of the parent and child. This
        # will assimilate the child +Document+ into the parent's object graph.
        #
        # Options:
        #
        # target: The target(parent) object
        # document: The +Document+ to update.
        # options: The association +Options+
        #
        # Example:
        #
        # <tt>ReferencedIn.update(person, game, options)</tt>
        def update(target, document, options)
          if options.polymorphic?
            puts "Setting poly #{target.inspect}"
            document.send("#{options.foreign_key}=", target)
            puts "Set FK to #{document.send(options.foreign_key).inspect}"
          else
            document.send("#{options.foreign_key}=", target ? target.id : nil)
          end
          
          new(document, options, target)
        end

        # Validate the options passed to the referenced in macro, to encapsulate
        # the behavior in this class instead of the associations module.
        #
        # Options:
        #
        # options: Thank you captain obvious.
        def validate_options(options = {})
          check_dependent_not_allowed!(options)
        end
      end
    end
  end
end
