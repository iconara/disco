# encoding: utf-8

module Disco
  class Connection
    attr_reader :upstream_instance, :downstream_instance, :upstream_port, :downstream_port, :properties

    def initialize(*args)
      @upstream_instance, @downstream_instance, @upstream_port, @downstream_port, @properties = args
      @properties ||= {}
    end

    def eql?(other)
      self.upstream_port == other.upstream_port &&
        self.downstream_port == other.downstream_port &&
        self.upstream_instance == other.upstream_instance &&
        self.downstream_instance == other.downstream_instance
    end
    alias_method :==, :eql?

    def hash
      @h ||= begin
        parts = [upstream_instance, downstream_instance, upstream_port, downstream_port]
        parts.reduce(31) { |h, p| (h & 33554431) * 31 ^ p.hash }
      end
    end

    def to_s
      @s ||= "Connection(#{upstream_instance}, #{downstream_instance}, #{upstream_port}, #{downstream_port}, #{properties.inspect})"
    end

    def to_h
      {
        :upstream_host => upstream_instance.name || upstream_instance.private_ip_address,
        :downstream_host => downstream_instance.name || downstream_instance.private_ip_address,
        :upstream_port => upstream_port,
        :downstream_port => downstream_port,
        :properties => @properties
      }
    end

    def self.from_h(h, instances)
      upstream_host = h[:upstream_host] || h['upstream_host']
      downstream_host = h[:downstream_host] || h['downstream_host']
      upstream_instance = instances[upstream_host]
      downstream_instance = instances[downstream_host]
      raise ArgumentError, "Could not find instance for #{upstream_host}" unless upstream_instance
      raise ArgumentError, "Could not find instance for #{downstream_host}" unless downstream_instance
      self.new(
        upstream_instance,
        downstream_instance,
        h[:upstream_port] || h['upstream_port'],
        h[:downstream_port] || h['downstream_port'],
        h[:properties] || h['properties']
      )
    end
  end
end