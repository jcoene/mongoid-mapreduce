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
        options[:map_key] = map_key
        reducer = Reducer.new(self, criteria.selector, options)
        reducer.instance_eval(&block) if block.present?
        reducer.run
      end

    end

  end
end
