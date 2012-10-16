require_relative '../spec_helper'


module Disco
  describe DotRenderer do
    let(:instance101) { stub(:private_ip_address => '101.101.101.101', :name => 'layer101.example.com') }
    let(:instance102) { stub(:private_ip_address => '102.102.102.102', :name => 'layer102.example.com') }
    let(:instance201) { stub(:private_ip_address => '201.201.201.201', :name => 'layer201.example.com') }
    let(:instance202) { stub(:private_ip_address => '202.202.202.202', :name => 'layer202.example.com') }
    let(:instance301) { stub(:private_ip_address => '301.301.301.301', :name => 'layer301.example.com') }
    let(:instance302) { stub(:private_ip_address => '302.302.302.302', :name => 'layer302.example.com') }

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

    describe '#render' do
      let :output do
        io = StringIO.new
        renderer.render(connections, io)
        io.string
      end

      it 'prints a digraph onto the specified IO' do
        output.should include('digraph topology {')
      end

      it 'prints graph settings' do
        output.scan(/graph \[(.+?)\]/).flatten.first.should include('overlap=false')
        output.scan(/node \[(.+?)\]/).flatten.first.should include('shape=rect')
      end

      it 'prints nodes' do
        nodes = output.scan(/^\s+(\S+) \[label="(.+?)"\]/)
        nodes.should include(['i102x102x102x102', 'layer102.example.com'])
      end

      it 'prints connections' do
        connections = output.scan(/^\s+(\S+) -> (\S+) \[label="(.+?)"\]/)
        connections.should include(['i102x102x102x102', 'i201x201x201x201', '1234'])
        connections.should include(['i202x202x202x202', 'i302x302x302x302', '3412'])
      end

      it 'does not include connections rejected by the filter' do
        filter.stub(:include?).with(connections.last).and_return(false)
        connections = output.scan(/^\s+(\S+) -> (\S+) \[label="(.+?)"\]/)
        connections.should_not include(['i202x202x202x202', 'i302x302x302x302', '13412'])
      end

      it 'does not print duplicate connections' do
        connections = output.scan(/^\s+(\S+) -> (\S+) \[label="(.+?)"\]/)
        selected_connections = connections.select { |i0, i1, p| i0 == 'i101x101x101x101' && i1 == 'i201x201x201x201' && p == '1234' }
        selected_connections.should have(1).item
      end
    end
  end
end
