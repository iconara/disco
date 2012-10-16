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
        process_data(extract_from_line(line))
      end
      compact_connections(connections)
    end

    protected

    def process_data(data)
      if data && data.all?
        data[0] = @port_mapper.numeric_port(data[0])
        data[2] = @port_mapper.numeric_port(data[2])
        data << {} unless data.length == 4
        data
      else
        nil
      end
    end

    def compact_connections(connections)
      connections.compact!
      connections.reject! { |_, host, _| host == '127.0.0.1' }
      connections
    end

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
    def extract_connections(str)
      return [] unless str
      lines = str.split("\n").drop(1)
      connections = lines.each_slice(2).map do |connection_str, properties_str|
        data = connection_str.scan(/:(\d+)\s+(\S+):(\d+)\s+$/).first
        send_speed = properties_str.scan(/send (\S+bps)/).first
        if data && send_speed
          data << {'send' => send_speed.first}
        end
        process_data(data)
      end
      compact_connections(connections)
    end

    protected

    def command
      '/usr/sbin/ss --tcp --numeric --info state established'
    end
  end
end