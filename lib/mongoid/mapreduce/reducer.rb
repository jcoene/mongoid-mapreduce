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

      # Obtain the field we are using for the map, if using an array values map.
      #
      # Returns true or false
      def map_array_field
        @fields.select { |k, v| v[:formula] == :array_values }.first
      end

      # Determines whether or not we are mapping from an array value
      #
      # Returns true or false
      def map_from_array?
        @fields.select { |k, v| v[:formula] == :array_values }.any?
      end

      # Generates the JavaScript map function
      #
      # If we have any fields defined with a map function of :array_values, use that to map
      # otherwise, use our aggregate map function.
      #
      # Returns String
      def map
        fn =  "function() { "
        if map_from_array?
          fn << map_array_values(map_array_field)
        else
          fn << map_aggregates
        end
        fn << "}"
        fn
      end

      # Generate a map function from one unique map key and a number of aggregate sources
      #
      #
      def map_aggregates
        fields = @fields.select { |k, v| v[:formula] == :aggregate }
        "emit (this.#{@map_key}, [#{[1, fields.collect{|k,v| "this.#{k}"}].flatten.join(", ")}]); "
      end

      # Generate a map function from one unique map key and a number of aggregate sources
      #
      #
      def map_array_values(field)
        "this.#{field[0].to_s}.forEach(function(value) { emit(value, 1); }); "
      end

      # Generates the JavaScript reduce function
      #
      # Returns String
      def reduce
        fn = "function(k, v) { "
        if map_from_array?
          fn << reduce_array_values
        else
          fn << reduce_aggregates
        end
        fn << "}"
        fn
      end

      # Generates a reduce function for aggregate map
      #
      # Returns String
      def reduce_aggregates
        fields = @fields.select { |k, v| v[:formula] == :aggregate }
        fn = ""
        fn << "var results = [#{(["0"] * (fields.length + 1)).flatten.join(", ")}]; "
        fn << "v.forEach(function(val) { "
        fn <<   "for(var i=0; i<= #{fields.length}; i++) { "
        fn <<     "results[i] += (typeof val[i] == Boolean) ? (val[i] ? 1 : 0) : val[i] "
        fn <<   "} "
        fn << "}); "
        fn << "return results.toString(); "
      end

      # Generates a reduce function for array values
      #
      # Returns String
      def reduce_array_values
        fn = ""
        fn << "var result = 0; "
        fn << "v.forEach(function(val) { result += val; }); "
        fn << "return result; "
      end

      # Adds a field to the map/reduce operation
      #
      # sym - String or Symbol, name of field to add
      #
      # Returns nothing.
      def field(sym, options={})
        options[:type] ||= Integer
        options[:formula] ||= :aggregate
        @fields[sym.to_sym] = options
      end

      # Serialize an object to the specified class
      #
      # obj - Object to serialize
      # klass - Class to prefer
      #
      # Returns serialized object or nil
      def serialize(obj, klass)
        return nil if obj.blank?
        obj = obj.is_a?(Boolean) ? (obj ? 1 : 0) : obj
        obj = obj.to_s =~ /(^[-+]?[0-9]+$)|(\.0+)$/ ? Integer(obj) : Float(obj)
        Mongoid::Fields::Mappings.for(klass).allocate.serialize(obj)
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
            d = (k.values[1].is_a?(String) ? k.values[1].split(',') : k.values[1])

            if d.is_a?(Array)
              doc = Document.new :_key_name => @map_key.to_s, :_key_value => idx, @map_key => idx, @count_field => d[0].to_i
              @fields.each_with_index do |h, i|
                doc[h[0].to_sym] = serialize(d[i + 1], h[1][:type])
              end
            else
              f = map_array_field[0]
              k = serialize(idx, map_array_field[1][:type])
              v = d.to_i
              doc = Document.new :_key_name => f, :_key_value => k, k.to_s => v, @count_field => v
            end
            h << doc
          end
        end

      end

    end

  end
end
