module Mongoid
  module MapReduce

    class Reducer

      attr_accessor :count_field

      # Initialize the reducer with given values
      #
      # klass - Mongoid model Class
      # selector - Selector to use for search (often from criteria)
      # map_key - Key to use in map function
      #
      # Returns nothing
      def initialize(klass, selector, map_key)
        @klass = klass
        @selector = selector
        @map_key = map_key
        @count_field = :_count
        @fields = {}
      end

      # Generates the JavaScript map function
      #
      # Returns String
      def map
        "function() { emit(this.#{@map_key}, [1, #{@fields.collect{|k,v| "this.#{k}"}.join(", ")}]); }"
      end

      # Generates the JavaScript reduce function
      #
      # Returns String
      def reduce
        "function(k, v) { var results = [0#{",0" * @fields.length}]; v.forEach(function(v){ [0,#{@fields.keys.collect.with_index{|k,i| i+1}.join(",")}].forEach(function(k){ results[k] += v[k] }) }); return results.toString(); }"
      end

      # Adds a field to the map/reduce operation
      #
      # sym - String or Symbol, name of field to add
      #
      # Returns nothing.
      def field(sym, options={})
        options[:type] ||= Integer
        options[:map] ||= :simple
        @fields[sym.to_sym] = options
      end

      # Runs the map/reduce operation and returns the result
      #
      # Returns Mongoid::MapReduce::Results object (array)
      # containing Mongoid::MapReduce::Document objects (hashes)
      def run
        begin
          res = @klass.collection.map_reduce(map, reduce, { query: @selector, out: "#map_reduce" } ).find.to_a
          return res.inject(Results.new) do |h, k|
            idx = k.values[0]
            d = (k.values[1].is_a?(String) ? k.values[1].split(',') : k.values[1]).collect {|i| i.is_a?(Boolean) ? (i ? 1 : 0) : i.to_i }
            doc = Document.new :_key_name => @map_key.to_sym, :_key_value => idx, @map_key.to_sym => idx, @count_field.to_sym => d[0]
            @fields.keys.each_with_index do |k, i|
              doc[k.to_sym] = d[i + 1]
            end
            h << doc
          end
        end

      end

    end

  end
end
