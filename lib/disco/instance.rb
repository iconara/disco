# encoding: utf-8

module Disco
  class Instance
    def initialize(data)
      @data = data.dup.freeze
    end

    def name
      @data['tags']['Name']
    end

    def eql?(other)
      other.respond_to?(:private_ip_address) && self.private_ip_address == other.private_ip_address
    end
    alias_method :==, :eql?

    def hash
      @h ||= private_ip_address.hash
    end

    def to_s
      @s ||= %[Instance("#{name || private_ip_address}")]
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