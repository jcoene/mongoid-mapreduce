require 'mongoid/mapreduce/formula/aggregate_fields.rb'
require 'mongoid/mapreduce/formula/array_values.rb'

module Mongoid
  module MapReduce

    class Reducer

      attr_accessor :count_field

      # Initialize the reducer with given values
      #
      # klass - Mongoid model Class
      # selector - Selector to use for search (often from criteria)
      # options - Hash of options:
      #             count_field - Name of field used to store count in results
      #             formula - Name of formula to be used (underscore)
      #             map_key - Name of field used as key in map function
      #
      # Returns nothing
      def initialize(klass, selector, options)
        options[:klass] = klass
        options[:selector] = selector
        options[:formula] ||= :aggregate_fields

        @klass = klass
        @selector = selector
        @formula_name = options[:formula]
        @options = options
        @fields = {}

        if options.key?(:fields)
          options[:fields].each do |f|
            field f.to_sym
          end
        end
      end

      # Expose the currently selected formula, from instance variable if possible.
      #
      # Returns Formula object.
      def formula
        # Find and initialize our formula
        klass = "Mongoid::MapReduce::Formula::#{@formula_name.to_s.camelize}"
        begin
          @formula ||= klass.constantize.new(@fields, @options)
        rescue NameError
          raise "Could not load formula for #{klass}"
        end
      end

      # Adds a field to the map/reduce operation
      #
      # sym - String or Symbol, name of field to add
      #
      # Returns nothing.
      def field(sym, options={})
        options[:type] ||= Integer
        @fields[sym.to_sym] = options
      end

      # Runs the map/reduce operation and returns the result
      #
      # Returns Mongoid::MapReduce::Results object (array)
      # containing Mongoid::MapReduce::Document objects (hashes)
      def run
        begin
          coll = @klass.collection.map_reduce(formula.map, formula.reduce, { :query => @selector, :out => "#map_reduce" } ).find.to_a
        rescue
          raise "Error: could not execute map reduce function"
        end

        formula.process(coll)
      end

    end

  end
end
