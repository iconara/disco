# encoding: utf-8

module Disco
  class Instance
    EC2_PROPERTIES = %w[instance_id public_dns_name private_dns_name private_ip_address instance_type launch_time availability_zone].map(&:to_sym)

    def initialize(data)
      @data = data.dup.freeze
    end

    def id
      instance_id
    end

    def name
      tags['Name']
    end

    def tags
      @data['tags']
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

    EC2_PROPERTIES.each do |property|
      define_method(property) do
        @data[property.to_s]
      end
    end
  end
end