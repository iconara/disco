# encoding: utf-8

require 'aws'
require 'json'
require 'ipaddr'


module Disco
  class InstanceRegistry
    def initialize(instances)
      @instances = instances
      make_mappings
    end

    def get(name)
      @mappings[name]
    end
    alias_method :[], :get

    def find(tag_criteria)
      @instances.select do |instance|
        values = instance.tags.values_at(*tag_criteria.keys)
        values == tag_criteria.values
      end
    end

    def size
      @instances.size
    end

    private

    def make_mappings
      @mappings = {}
      @instances.each do |instance|
        @mappings[instance.name] = instance if instance.name
        @mappings[instance.id] = instance
        @mappings[instance.public_dns_name] = instance
        @mappings[instance.private_dns_name] = instance
        @mappings[instance.private_ip_address] = instance
        @mappings[IPAddr.new(instance.private_ip_address).ipv4_mapped.to_s] = instance
      end
    end
  end

  class InstanceCache
    include EventDispatch

    def initialize(*args)
      @cache_path, @ec2, @instance_filter = args
      @instance_filter ||= NullFilter.new
    end

    def instances
      cache!
      @registry
    end

    private

    def cache!
      unless @mappings
        read_cache
        unless @instances && @registry
          find_instances
          write_cache
          read_cache
        end
      end
    end

    def read_cache
      if File.exists?(@cache_path)
        @instances = JSON.parse(File.read(@cache_path)).map { |data| Instance.new(data) }
        @instances = @instances.select { |instance| @instance_filter.include?(instance) }
        @registry = InstanceRegistry.new(@instances)
      end
    end

    def write_cache
      File.open(@cache_path, 'w') { |io| io.write(JSON.pretty_generate(@instances.map(&:to_h))) }
    end

    def find_instances
      @instances = []
      @ec2.each_instance do |instance|
        begin
          data = Hash[Instance::EC2_PROPERTIES.map { |property| [property.to_s, instance.send(property)] }]
          data['tags'] = Hash[instance.tags.map { |k, v| [k, v] }]
          instance = Instance.new(data)
          trigger(:instance_loaded, instance: instance)
          @instances << instance
        rescue AWS::EC2::Errors::RequestLimitExceeded => e
          trigger(:load_error, message: e.message)
          sleep(5)
          retry
        end
      end
    end
  end

  class Ec2
    def initialize(aws, properties={})
      @aws = aws
      @ec2 = @aws::EC2.new(properties)
    end

    def each_instance(&block)
      @aws.memoize do
        @ec2.instances.each(&block)
      end
    end
  end
end