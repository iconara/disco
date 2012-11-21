require_relative '../spec_helper'


module Disco
  describe GexfRenderer do
    let(:instance101) { stub(:instance101, :id => 'i-101a101b', :name => 'layer101.example.com', :tags => {'Role' => 'web'}) }
    let(:instance102) { stub(:instance102, :id => 'i-102a102b', :name => 'layer102.example.com', :tags => {'Role' => 'web'}) }
    let(:instance201) { stub(:instance201, :id => 'i-201a201b', :name => 'layer201.example.com', :tags => {'Role' => 'mq'}) }
    let(:instance202) { stub(:instance202, :id => 'i-202a202b', :name => 'layer202.example.com', :tags => {'Role' => 'mq'}) }
    let(:instance301) { stub(:instance301, :id => 'i-301a301b', :name => 'layer301.example.com', :tags => {'Role' => 'db'}) }
    let(:instance302) { stub(:instance302, :id => 'i-302a302b', :name => 'layer302.example.com', :tags => {'Role' => 'db'}) }

    let :connections do
      [
        Connection.new(instance101, instance201, 62312, 1234),
        Connection.new(instance101, instance201, 63457, 1234),
        Connection.new(instance102, instance201, 62312, 1234),
        Connection.new(instance201, instance301, 62312, 3412),
        Connection.new(instance202, instance302, 62312, 3412),
        Connection.new(instance202, instance302, 35345, 13412)
      ]
    end

    let :filter do
      stub(:filter, :include? => true)
    end

    let :renderer do
      described_class.new(filter)
    end

    let :ns_opts do
      {'gexf' => GexfRenderer::GEXF_NS_URI}
    end

    describe '#render' do
      def render_to_doc(connections)
        io = StringIO.new
        renderer.render(connections, io)
        Nokogiri.XML(io.string, nil, 'UTF-8')
      end

      let :output do
        render_to_doc(connections)
      end

      it 'prints a GEXF document to the specified IO' do
        output.root.name.should == 'gexf'
        output.root.namespace.href.should == GexfRenderer::GEXF_NS_URI
      end

      it 'prints a directed graph' do
        type = output.xpath('/gexf:gexf/gexf:graph/@defaultedgetype', ns_opts).map(&:value).first
        type.should == 'directed'
      end

      it 'prints graph metadata' do
        last_modified = output.xpath('/gexf:gexf/gexf:meta/@lastmodifieddate', ns_opts).map(&:value).first
        creator = output.xpath('/gexf:gexf/gexf:meta/gexf:creator/text()', ns_opts).map(&:content).first
        description = output.xpath('/gexf:gexf/gexf:meta/gexf:description/text()', ns_opts).map(&:content).first
        last_modified.should == Time.now.strftime('%Y-%m-%d')
        creator.should == 'Disco'
        description.should == 'Topology'
      end

      it 'prints nodes' do
        matches = output.xpath('/gexf:gexf/gexf:graph/gexf:nodes/gexf:node[@id = "i102a102b" and @label = "layer102.example.com"]', ns_opts)
        matches.should_not be_empty
      end

      it 'prints connections' do
        matches = output.xpath('/gexf:gexf/gexf:graph/gexf:edges/gexf:edge[@source = "i102a102b" and @target = "i201a201b"]', ns_opts)
        matches.should_not be_empty
        matches.first['label'].should == '1234'
      end

      it 'does not include connections rejected by the filter' do
        filter.stub(:include?).with(connections[2]).and_return(false)
        matches = output.xpath('//gexf:edge[@source = "i102a102b" and @target = "i201a201b"]', ns_opts)
        matches.should be_empty
      end

      it 'does not print duplicate connections' do
        matches = output.xpath('//gexf:edge[@source = "i101a101b" and @target = "i201a201b"]', ns_opts)
        matches.should have(1).item
      end

      context 'with network speed data' do
        let :connections do
          [
            Connection.new(instance101, instance102, 10101, 2000, {'send' => '10Mbps'}),
            Connection.new(instance102, instance101, 2000, 10101, {'send' => '2Mbps'}),
            Connection.new(instance102, instance201, 2000, 30303, {'send' => '1Mbps'}),
            Connection.new(instance201, instance102, 30303, 2000, {'send' => '20Mbps'}),
            Connection.new(instance301, instance302, 1000, 2000, {'send' => '30Mbps'}),
            Connection.new(instance302, instance301, 2000, 1000, {'send' => '1Mbps'})
          ]
        end

        let :output do
          render_to_doc(connections)
        end

        it 'chooses directions based on the network speed metadata' do
          edges = output.xpath('//gexf:edge', ns_opts).map { |e| [e['source'], e['target'], e['label']] }
          edges.should include(['i101a101b', 'i102a102b', '2000'])
          edges.should include(['i201a201b', 'i102a102b', '2000'])
          edges.should include(['i301a301b', 'i302a302b', '2000'])
          edges.should_not include(['i102a102b', 'i101a101b', '10101'])
        end
      end
    end
  end
end
