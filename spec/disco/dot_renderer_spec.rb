require_relative '../spec_helper'


module Disco
  describe DotRenderer do
    let :connections do
      [
        Connection.new(stub(:short_name => 'layer101'), stub(:short_name => 'layer201'), 1234),
        Connection.new(stub(:short_name => 'layer102'), stub(:short_name => 'layer201'), 1234),
        Connection.new(stub(:short_name => 'layer201'), stub(:short_name => 'layer301'), 3412),
        Connection.new(stub(:short_name => 'layer202'), stub(:short_name => 'layer302'), 3412),
        Connection.new(stub(:short_name => 'layer202'), stub(:short_name => 'layer302'), 13412)
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
        output.should include('digraph {')
      end

      it 'prints graph settings' do
        output.scan(/graph \[(.+?)\]/).flatten.first.should include('overlap=false')
        output.scan(/node \[(.+?)\]/).flatten.first.should include('shape=rect')
      end

      it 'prints connections' do
        connections = output.scan(/^\s+(\S+) -> (\S+) \[label=(.+?)\]/)
        connections.should include(['layer102', 'layer201', '1234'])
        connections.should include(['layer202', 'layer302', '3412'])
      end

      it 'does not include connections rejected by the filter' do
        filter.stub(:include?).with(connections.last).and_return(false)
        connections = output.scan(/^\s+(\S+) -> (\S+) \[label=(.+?)\]/)
        connections.should_not include(['layer202', 'layer302', '13412'])
      end
    end
  end
end
