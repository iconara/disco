# encoding: utf-8

require 'json'
require 'ipaddr'
require 'net/ssh'
require 'set'


module Disco
  class InstanceCache
    def initialize(*args)
      @ec2, @cache_path = args
    end

    def cache!
      read_cache
      unless defined? @instances
        find_instances
        write_cache
        read_cache
      end
    end

    def resolve_name(name)
      node = get(name)
      node.name if node
    end

    def get(name)
      @mappings[name]
    end
    alias_method :[], :get

    private

    def read_cache
      if File.exists?(@cache_path)
        @instances = JSON.parse(File.read(@cache_path)).map { |data| Instance.new(data) }
        make_mappings
      end
    end

    def write_cache
      File.open(@cache_path, 'w') { |io| io.write(@instances.map(&:to_h).to_json) }
    end

    def make_mappings
      @mappings = {}
      @instances.each do |instance|
        @mappings[instance.name] = instance
        @mappings[instance.private_dns_name] = instance
        @mappings[instance.private_ip_address] = instance
        @mappings[IPAddr.new(instance.private_ip_address).ipv4_mapped.to_s] = instance
      end
    end

    def find_instances
      @instances = []
      @ec2.instances.each do |instance|
        begin
          data = {
            :public_dns_name => instance.public_dns_name,
            :private_dns_name => instance.private_dns_name,
            :private_ip_address => instance.private_ip_address,
            :instance_type => instance.instance_type,
            :launch_time => instance.launch_time.to_i
          }
          instance.tags.each do |k, v|
            data[k.downcase.to_sym] = v
          end
          @instances << Instance.new(data)
        rescue AWS::EC2::Errors::RequestLimitExceeded => e
          sleep(5)
          retry
        end
      end
    end
  end

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

  class NullFilter
    def include?(name)
      true
    end
  end

  class ProcFilter
    def initialize(&block)
      @filter = block
    end

    def include?(name)
      @filter.call(name)
    end
  end

  class Instance
    def initialize(data)
      @data = data.dup.freeze
    end

    def short_name
      @short_name ||= @data['name'] && @data['name'].split('.').first
    end

    def eql?(other)
      self.name == other.name
    end

    def hash
      name.hash
    end

    def to_s
      @s ||= %[Instance("#{name}")]
    end

    def to_h
      @data
    end

    def method_missing(name, *args)
      @data[name.to_s]
    end
  end

  class Connection
    attr_reader :upstream, :downstream, :port

    def initialize(*args)
      @upstream, @downstream, @port = args
    end

    def eql?(other)
      self.upstream == other.upstream && self.downstream == other.downstream && self.port == other.port
    end
    alias_method :==, :eql?

    def hash
      @hash ||= (((upstream.hash * 31) ^ (downstream.hash)) * 31) ^ port
    end
  end

  class DotRenderer
    def initialize(service_mappings)
      @service_mappings = service_mappings
    end

    def render(connections, io=$stdout)
      io.puts("digraph {")
      io.puts("\tgraph [overlap=false];")
      io.puts("\tnode [shape=rect];")
      connections.each do |c|
        prefix = @service_mappings.service?(c.port) ? '' : '#'
        io.puts(sprintf("%s\t%s -> %s [label=%d];", prefix, c.upstream.short_name, c.downstream.short_name, c.port))
      end
      io.puts('}')
    end
  end

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

  class ConnectionExplorer
    def initialize(instance_cache, parser_factory, options={})
      @instance_cache = instance_cache
      @lsof_parser = parser_factory.lsof
      @netstat_parser = parser_factory.netstat
      @username = options[:username]
      @ssh_factory = options[:ssh_factory] || Net::SSH
      @sampling_duration = options[:sampling_duration] || 0.0
    end

    def discover_connections(instance, options={})
      connections = []
      @ssh_factory.start(instance.name, @username) do |session|
        stop_at = Time.now + @sampling_duration
        begin
          if output = session.exec!(LSOF_COMMAND)
            connections.concat(@lsof_parser.extract_connections(output))
          elsif output = session.exec!(NETSTAT_COMMAND)
            connections.concat(@netstat_parser.extract_connections(output))
          end
        end while Time.now < stop_at
      end
      connections.uniq!
      connections.map do |downstream, port|
        downstream_instance = @instance_cache[downstream]
        if downstream_instance && instance && downstream_instance != instance
          Connection.new(instance, downstream_instance, port)
        end
      end.compact
    end

    private

    LSOF_COMMAND = '/usr/sbin/lsof -i'.freeze
    NETSTAT_COMMAND = 'netstat --tcp --numeric'.freeze
  end

  class TopologyExplorer
    def initialize(*args)
      @connection_explorer, @instance_cache, @filter = args
      @filter ||= NullFilter.new
    end

    def discover_topology(seed_nodes)
      exploration_queue = seed_nodes.map { |name| @instance_cache[name] }
      topology = Set.new
      visited_instances = Set.new
      while instance = exploration_queue.pop
        next if visited_instances.include?(instance)
        connections = @connection_explorer.discover_connections(instance)
        connections.each do |connection|
          exploration_queue << connection.downstream if @filter.include?(connection.downstream)
          topology << connection
        end
        visited_instances << instance
        exploration_queue.uniq!
      end
      topology
    end
  end
end