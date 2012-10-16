# encoding: utf-8

module Disco
  class Instance
    def initialize(data)
      @data = data.dup.freeze
    end

    def id
      instance_id
    end

    def name
      @data['tags']['Name']
    end

    def eql?(other)
      self.id == other.id
    end
    alias_method :==, :eql?

    def hash
      @h ||= id.hash
    end

    def to_s
      @s ||= %[Instance("#{id}", "#{name}")]
    end

    def to_h
      @data
    end

    def respond_to?(method_name)
      @data.key?(method_name.to_s)
    end

    def method_missing(method_name, *args)
      @data[method_name.to_s]
    end
  end
end