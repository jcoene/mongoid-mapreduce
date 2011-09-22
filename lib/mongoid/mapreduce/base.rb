module Mongoid
  module MapReduce

    extend ActiveSupport::Concern

    module ClassMethods

      # Run a map/reduce operation on the current model
      #
      # map_key: Symbol or String, the field used in the map function
      #
      # Returns a Hash of results
      def map_reduce(map_key=:_id, options={}, &block)
        reducer = Reducer.new(self, criteria.selector, map_key)

        if options.key?(:count_field)
          reducer.count_field = options[:count_field].to_sym
        end

        if options.key?(:fields)
          reducer.fields = options[:fields].collect {|f| f.to_sym }
        end

        reducer.instance_eval(&block) if block.present?
        reducer.run
      end

    end

  end
end
