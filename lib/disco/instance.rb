# encoding: utf-8

module Disco
  class Instance
    def initialize(data)
      @data = data.dup.freeze
    end

    def short_name
      @short_name ||= @data['name'] && @data['name'].split('.').first
    end

    def eql?(other)
      self.name == other.name
    end

    def hash
      name.hash
    end

    def to_s
      @s ||= %[Instance("#{name}")]
    end

    def to_h
      @data
    end

    def method_missing(name, *args)
      @data[name.to_s]
    end
  end
end