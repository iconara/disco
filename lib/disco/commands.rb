# encoding: utf-8

module Disco
  class ConnectionCommand
    def initialize(port_mapper=nil)
      @port_mapper = port_mapper || SimplePortMapper.new
    end

    def connections(ssh_session)
      extract_connections(ssh_session.exec!(command))
    end

    def extract_connections(str)
      return [] unless str
      connections = str.split("\n").map do |line|
        triplet = extract_from_line(line)
        if triplet && triplet.all?
          triplet[0] = @port_mapper.numeric_port(triplet[0])
          triplet[2] = @port_mapper.numeric_port(triplet[2])
          triplet
        else
          nil
        end
      end
      connections.compact!
      connections.reject! { |_, host, _| host == '127.0.0.1' }
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
      line.scan(/:([^:]+)\s+(\S+):(\d+)\s+\w+\s*$/).first
    end
  end

  class LsofCommand < ConnectionCommand
    protected
    
    def command
      '/usr/sbin/lsof -i'
    end

    def extract_from_line(line)
      line.scan(/:(\S+)->(.+?\.compute\.internal):(\S+)/).first
    end
  end

  class SsCommand < ConnectionCommand
    protected

    def command
      '/usr/sbin/ss --tcp --numeric --info state established'
    end

    def extract_from_line(line)
      line.scan(/:(\d+)\s+(\S+):(\d+)\s+$/).first
    end
  end
end