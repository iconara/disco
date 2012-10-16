# encoding: utf-8

module Disco
  class SimplePortMapper
    def numeric_port(str)
      return nil unless str =~ /^\d+$/
      str.to_i
    end
  end

  class ServicePortMapper < SimplePortMapper
    def initialize(options={})
      @path = options[:path] || '/etc/services'
      @custom_mappings = options[:custom] || {}
    end

    def numeric_port(str)
      super or begin
        cache_mappings unless defined? @mappings
        @mappings[str]
      end
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