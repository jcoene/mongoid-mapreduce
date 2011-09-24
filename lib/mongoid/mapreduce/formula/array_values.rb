require 'mongoid/mapreduce/serialization'

module Mongoid
  module MapReduce
    module Formula

      class ArrayValues
        include Mongoid::MapReduce::Serialization

        def initialize(fields, options={})
          options[:map_key] ||= :_id
          options[:count_type] ||= Integer
          options[:count_field] ||= :_count

          if fields.length > 1
            raise "Error: The Array Values formula can only take 1 field"
          end

          @field_name = options[:map_key]
          @field_type = options[:count_type]
          @count_field = options[:count_field]
        end

        # Generate a map function
        # Emits the value 1 for each value of the given array field
        #
        # Returns String
        def map
          fn =  "function() { "
          fn <<   "this.#{@field_name.to_s}.forEach(function(value) { "
          fn <<     "emit(value, 1); "
          fn <<   "}); "
          fn << "}"
        end

        # Generates a reduce function
        # Adds the given values
        #
        # Returns String
        def reduce
          fn =  "function(k, v) { "
          fn <<   "var result = 0; "
          fn <<   "v.forEach(function(val) { result += val; }); "
          fn <<   "return result; "
          fn << "}"
        end

        # Process the results of a given collection
        #
        # collection - the MongoDB collection returned from the map/reduce op
        #
        # Returns Results
        def process(collection)
          return collection.inject(Results.new) do |h, k|
            key = k.values[0].to_s =~ /(^[-+]?[0-9]+$)|(\.0+)$/ ? Integer(k.values[0]) : Float(k.values[0])
            val = serialize(k.values[1].is_a?(String) ? k.values[1].split(',') : k.values[1], @field_type)
            h << Document.new(:_key_name => @field_name, :_key_value => key, key.to_s => val, @count_field => val)
          end
        end

      end

    end
  end
end
