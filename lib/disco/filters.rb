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
end