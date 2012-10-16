# encoding: utf-8

module Disco
  class ConnectionCommand
    def initialize(port_mapper)
      @port_mapper = port_mapper
    end

    def connections(ssh_session)
      extract_connections(ssh_session.exec!(command))
    end

    def extract_connections(str)
      return [] unless str
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

    def command
      raise 'Override #command in a subclass!'
    end

    def extract_from_line(line)
      raise 'Override #extract_from_line in a subclass!'
    end
  end

  class NetstatCommand < ConnectionCommand
    protected

    def command
      'netstat --tcp --numeric'
    end

    def extract_from_line(line)
      line.scan(/(\S+:\d+)\s+\w+\s*$/).first
    end
  end

  class LsofCommand < ConnectionCommand
    protected
    
    def command
      '/usr/sbin/lsof -i'
    end

    def extract_from_line(line)
      line.scan(/->(.+?\.compute\.internal:\S+)/).first
    end
  end

  class SsCommand < ConnectionCommand
    protected

    def command
      '/usr/sbin/ss --tcp --numeric --info state established'
    end

    def extract_from_line(line)
      line.scan(/\s+(\S+:\d+)\s+$/).first
    end
  end
end