module Mongoid
  module MapReduce

    class Document < Hash

      # Accept a hash of attributes dring initialization
      #
      # attrs - Hash of attributes to initialize with
      #
      # Returns value of super
      def initialize(attrs)
        attrs.each do |k, v|
          self[k.to_sym] = v
        end
        super
      end

      # Allow dot notation on our Document
      #
      # sym - Symbol/String of the missing value
      # args - Arguments supplied
      # block - Block supplied
      #
      # Returns value of supplied symbol/string if exists
      def method_missing(sym, *args, &block)
        if self.has_key?(sym.to_sym)
          return self[sym.to_sym]
        elsif self.has_key?(sym.to_s)
          return self[sym.to_s]
        end
        super
      end

      # Converts the Results to a Hash
      #
      # Returns Hash
      def to_hash
        h = Hash.new
        self.each do |k, v|
          h[k.to_s] = v unless [:_key_name, :_key_value].include?(k)
        end
        h
      end

    end

  end
end
