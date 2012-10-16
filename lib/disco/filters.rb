# encoding: utf-8

module Disco
  class NullFilter
    def include?(name)
      true
    end
  end

  class ProcFilter
    def initialize(&block)
      @filter = block
    end

    def include?(name)
      @filter.call(name)
    end
  end

  class PortFilter
    def initialize(*ranges)
      @ranges = ranges
    end

    def include?(connection)
      @ranges.any? { |rng| rng === connection.port }
    end
  end
end