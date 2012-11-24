# encoding: utf-8

require 'disco/connection'
require 'disco/connection_explorer'
require 'disco/renderer_utils'
require 'disco/dot_renderer'
require 'disco/gexf_renderer'
require 'disco/event_dispatch'
require 'disco/filters'
require 'disco/instance'
require 'disco/instance_cache'
require 'disco/commands'
require 'disco/service_port_mapper'
require 'disco/topology_explorer'

module Disco
  class Disco
    attr_reader :instance_registry, :topology_explorer

    def initialize(*args)
      @instance_registry, @topology_explorer = args
    end
  end

  def self.create(options={})
    options = defaults.merge(options)
    ec2 = Ec2.new(AWS, ec2_endpoint: "ec2.#{options[:ec2_region]}.amazonaws.com")
    instance_registry = InstanceCache.new(options[:instance_cache_path], ec2).instances
    services = ServicePortMapper.new(custom: {'apani1' => 9160})
    discovery_commands = [SsCommand.new(services)]
    connection_explorer = ConnectionExplorer.new(discovery_commands, instance_registry, username: options[:username], sampling_duration: 10.0)
    Disco.new(instance_registry, TopologyExplorer.new(connection_explorer, instance_registry))
  end

  def self.defaults
    {:ec2_region => 'eu-west-1', :instance_cache_path => '.instances.json'}
  end
end