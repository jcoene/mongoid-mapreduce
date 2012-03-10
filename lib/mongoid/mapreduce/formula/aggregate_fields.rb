require 'mongoid/mapreduce/serialization'

module Mongoid
  module MapReduce
    module Formula

      class AggregateFields
        include Mongoid::MapReduce::Serialization

        def initialize(fields, options={})
          options[:map_key] ||= :_id
          options[:count_field] ||= :_count
          
          @map_key = options[:map_key]
          @map_key_as = options[:map_key_as] || @map_key
          @count_field = options[:count_field]
          @count_field_as = options[:count_field_as] || @count_field
          @fields = fields
        end

        # Generate a map function
        # Emits the map key with an array of field values
        #
        # Returns String
        def map
          fn =  "function() { "
          if @map_key.first == "("
            fn << "emit (#{@map_key}, [#{[1, @fields.collect{|k,v| "this.#{k}"}].flatten.join(", ")}]); "
          else
            fn <<   "emit (this.#{@map_key}, [#{[1, @fields.collect{|k,v| "this.#{k}"}].flatten.join(", ")}]); "
          end
          fn << "}"
          puts fn
          fn
        end

        # Generates a reduce function
        # Adds each value in the given array
        #
        # Returns String
        def reduce
          fn =  "function(k, v) { "
          fn <<   "var results = [#{(["0"] * (@fields.length + 1)).flatten.join(", ")}]; "
          fn <<   "v.forEach(function(val) { "
          fn <<     "for(var i=0; i<= #{@fields.length}; i++) { "
          fn <<       "results[i] += (typeof val[i] == Boolean) ? (val[i] ? 1 : 0) : val[i] "
          fn <<     "} "
          fn <<   "}); "
          fn <<   "return results.toString(); "
          fn << "}"
          puts fn
          fn
        end

        # Process the results of a given collection
        #
        # collection - the MongoDB collection returned from the map/reduce op
        #
        # Returns Results
        def process(collection)
          return collection.inject(Results.new) do |h, k|
            key = k.values[0]
            vals = (k.values[1].is_a?(String) ? k.values[1].split(',') : k.values[1])
            doc = Document.new :_key_name => @map_key_as.to_s, :_key_value => key, @map_key_as => key, @count_field_as => vals[0].to_i
            @fields.each_with_index do |f, i|
              doc[f[0].to_sym] = serialize(vals[i + 1], f[1][:type])
            end
            h << doc
          end
        end

      end

    end
  end
end
