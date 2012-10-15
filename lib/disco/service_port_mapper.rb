# encoding: utf-8

module Disco
  class ServicePortMapper
    def initialize(options={})
      @path = options[:path] || '/etc/services'
      @custom_mappings = options[:custom] || {}
      @significant_ports = options[:significant] || []
    end

    def numeric_port(str)
      return str.to_i if str =~ /^\d+$/
      cache_mappings unless defined? @mappings
      @mappings[str]
    end

    def service?(port)
      @significant_ports.any? { |rng| rng === port }
    end

    private

    def cache_mappings
      @mappings = {}
      File.open(@path) do |io|
        io.each_line do |line|
          service, port = line.scan(%r{^(\S+)\s+(\d+)/tcp}).flatten
          if service && port
            @mappings[service] = port.to_i
          end
        end
      end
      @mappings.merge!(@custom_mappings)
    end
  end
end