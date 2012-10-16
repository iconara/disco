require_relative '../spec_helper'


module Disco
  describe DotRenderer do
    let(:instance101) { stub(:id => 'i-101a101b', :name => 'layer101.example.com', :tags => {'Role' => 'web'}) }
    let(:instance102) { stub(:id => 'i-102a102b', :name => 'layer102.example.com', :tags => {'Role' => 'web'}) }
    let(:instance201) { stub(:id => 'i-201a201b', :name => 'layer201.example.com', :tags => {'Role' => 'mq'}) }
    let(:instance202) { stub(:id => 'i-202a202b', :name => 'layer202.example.com', :tags => {'Role' => 'mq'}) }
    let(:instance301) { stub(:id => 'i-301a301b', :name => 'layer301.example.com', :tags => {'Role' => 'db'}) }
    let(:instance302) { stub(:id => 'i-302a302b', :name => 'layer302.example.com', :tags => {'Role' => 'db'}) }

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

    let :colorizer do
      c = stub(:colorizer)
      c.stub(:colors) do |instance|
        case instance.tags['Role']
        when 'web' then ['black', 'red']
        when 'mq' then ['black', 'green']
        when 'db' then ['white', 'blue']
        else ['white', 'black']
        end
      end
      c
    end

    let :renderer do
      described_class.new(filter, colorizer)
    end

    describe '#render' do
      let :output do
        io = StringIO.new
        renderer.render(connections, io)
        io.string
      end

      it 'prints a digraph onto the specified IO' do
        output.should include('digraph "Topology" {')
      end

      it 'prints graph settings' do
        output.scan(/graph \[(.+?)\]/).flatten.first.should include('overlap=false')
        output.scan(/node \[(.+?)\]/).flatten.first.should include('shape="rect"')
        output.scan(/node \[(.+?)\]/).flatten.first.should include('style="filled"')
      end

      it 'prints nodes' do
        nodes = output.scan(/^\s+(\S+) \[.*label="(.+?)"/)
        nodes.should include(['i102a102b', 'layer102.example.com'])
      end

      it 'prints connections' do
        edges = output.scan(/^\s+(\S+) -> (\S+) \[.*label="(.+?)"/)
        edges.should include(['i102a102b', 'i201a201b', '1234'])
        edges.should include(['i202a202b', 'i302a302b', '3412'])
      end

      it 'does not include connections rejected by the filter' do
        filter.stub(:include?).with(connections.last).and_return(false)
        edges = output.scan(/^\s+(\S+) -> (\S+) \[.*label="(.+?)"/)
        edges.should_not include(['i202a202b', 'i302a302b', '13412'])
      end

      it 'does not print duplicate connections' do
        edges = output.scan(/^\s+(\S+) -> (\S+) \[.*label="(.+?)"/)
        selected_edges = edges.select { |i0, i1, p| i0 == 'i101a101b' && i1 == 'i201a201b' && p == '1234' }
        selected_edges.should have(1).item
      end

      it 'chooses directions based on the speed property' do
        connections = [
          Connection.new(instance101, instance102, 10101, 2000, {'speed' => '10Mbps'}),
          Connection.new(instance102, instance101, 2000, 10101, {'speed' => '2Mbps'}),
          Connection.new(instance102, instance201, 2000, 30303, {'speed' => '1Mbps'}),
          Connection.new(instance201, instance102, 30303, 2000, {'speed' => '20Mbps'}),
          Connection.new(instance301, instance302, 1000, 2000, {'speed' => '30Mbps'}),
          Connection.new(instance302, instance301, 2000, 1000, {'speed' => '1Mbps'})
        ]
        io = StringIO.new
        renderer.render(connections, io)
        edges = io.string.scan(/^\s+(\S+) -> (\S+) \[.*label="(.+?)"/)
        edges.should include(['i101a101b', 'i102a102b', '2000'])
        edges.should include(['i201a201b', 'i102a102b', '2000'])
        edges.should include(['i301a301b', 'i302a302b', '2000'])
        edges.should_not include(['i102a102b', 'i101a101b', '10101'])
      end

      it 'colorizes nodes with the colorizer' do
        edges = output.scan(/^\s+(\S+) \[.*fillcolor="(.+?)"/)
        edges.should include(['i102a102b', 'red'])
        edges.should include(['i201a201b', 'green'])
        edges.should include(['i302a302b', 'blue'])
      end

      it 'colorizes labels with the colorizer' do
        edges = output.scan(/^\s+(\S+) \[.*fontcolor="(.+?)"/)
        edges.should include(['i102a102b', 'black'])
        edges.should include(['i201a201b', 'black'])
        edges.should include(['i302a302b', 'white'])
      end
    end
  end
end
