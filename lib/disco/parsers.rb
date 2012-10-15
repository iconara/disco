# encoding: utf-8

module Disco
  class ConnectionParser
    def initialize(port_mapper)
      @port_mapper = port_mapper
    end

    def extract_connections(str)
      connections = str.split("\n").flat_map do |line|
        extract_from_line(line)
      end
      connections.compact!
      connections.map! do |str|
        h, p = str.scan(/^(.+):([\d\w]+)$/).flatten
        [h, @port_mapper.numeric_port(p)] if h && p
      end
      connections.compact!
      connections
    end

    protected

    def extract_from_line(line)
      raise 'Override #extract_from_line in a subclass!'
    end
  end

  class NetstatParser < ConnectionParser
    def initialize(port_mapper)
      @port_mapper = port_mapper
    end

    protected

    def extract_from_line(line)
      line.scan(/(\S+:\d+)\s+\w+\s*$/).first
    end
  end

  class LsofParser < ConnectionParser
    def extract_from_line(line)
      line.scan(/->(.+?\.compute\.internal:\S+)/).first
    end
  end

  class ParserFactory
    def initialize(port_mapper)
      @port_mapper = port_mapper
    end

    def lsof
      @lsof ||= LsofParser.new(@port_mapper)
    end

    def netstat
      @netstat ||= NetstatParser.new(@port_mapper)
    end
  end
end