# encoding: utf-8

require 'set'
require 'nokogiri'


module Disco
  class GexfRenderer
    include RendererUtils

    GEXF_NS_URI = 'http://www.gexf.net/1.2draft'.freeze

    def initialize(filter)
      @filter = filter
    end

    def render(connections, io=$stdout)
      doc = Nokogiri::XML::Document.new
      doc.add_child(create_root(doc))
      doc.root.add_child(create_meta(doc))
      doc.root.add_child(create_graph(doc, connections))
      doc.write_to(io)
    end

    private

    def create_root(doc)
      root = doc.create_element('gexf')
      root.default_namespace = GEXF_NS_URI
      root.add_namespace_definition('xsi', 'http://www.w3.org/2001/XMLSchemainstance')
      root['xsi:schemaLocation'] = 'http://www.gexf.net/1.2draft http://www.gexf.net/1.2draft/gexf.xsd'
      root['version'] = '1.2'
      root
    end

    def create_meta(doc)
      meta = doc.create_element('meta', lastmodifieddate: Time.now.strftime('%Y-%m-%d'))
      meta.add_child(doc.create_element('creator', 'Disco'))
      meta.add_child(doc.create_element('description', 'Topology'))
      meta
    end

    def create_graph(doc, connections)
      graph = doc.create_element('graph', defaultedgetype: 'directed')
      graph.add_child(create_nodes(doc, uniq_instances(connections)))
      graph.add_child(create_edges(doc, connections))
      graph
    end

    def create_nodes(doc, instances)
      nodes = doc.create_element('nodes')
      instances.each do |instance|
        nodes.add_child(doc.create_element('node', id: node_id(instance), label: instance.name))
      end
      nodes
    end

    def create_edges(doc, connections)
      edges = doc.create_element('edges')
      deduplicate_connections(connections).each do |c|
        if @filter.include?(c)
          upstream = node_id(c.upstream_instance)
          downstream = node_id(c.downstream_instance)
          port = c.downstream_port
          attributes = {
            :id => "#{upstream}-#{downstream}-#{port}",
            :source => upstream,
            :target => downstream,
            :label => port
          }
          edges.add_child(doc.create_element("edge", attributes))
        end
      end
      edges
    end
  end
end