module Mongoid
  module MapReduce

    class Results < Array

      # Allow [] to be used to find records by key
      #
      # value - Value of the index or value to search by
      #
      # Return record at index if Fixnum, or result of find(value)
      def [](value)
        unless value.is_a? Fixnum
          return find(value)
        end
        super
      end

      # Search for contained Documents by key
      #
      # value - Value of the map key
      #
      # Return Document or nil
      def find(value)
        self.each {|doc| return doc if doc._key_value == value }
        nil
      end

      # Returns a list of keys from contained documents
      #
      # Returns Array
      def keys
        self.collect {|d| d._key_value }
      end

      # Determines whether or not a key exists
      #
      # value - Value of the map key
      #
      # Returns true or false
      def has_key?(value)
        find(value) ? true : false
      end

      # Converts the Results to a Hash
      #
      # Returns Hash
      def to_hash
        self.each.inject({}){|h, doc| h[doc._key_value.to_s] = doc.to_hash; h }
      end

      # Simplifies the Results to a Hash containing only a key and a single value (the count)
      #
      # Returns Hash
      def counts
        self.each.inject({}) {|h, doc| h[doc._key_value.to_s] = doc._count; h }
      end

    end

  end
end
