require_relative '../spec_helper'


module Disco
  describe TopologyExplorer do
    stubs :instance1, :instance2, :instance3, :connection_explorer

    let :instance_cache do
      ic = stub(:instance_cache)
      ic.stub(:[]).with('host1').and_return(instance1)
      ic
    end

    let :explorer do
      described_class.new(connection_explorer, instance_cache)
    end

    describe '#discover_topology' do
      before do
        connection_explorer.stub(:discover_connections).with(instance1).and_return([Disco::Connection.new(instance1, instance2, 99, 1), Disco::Connection.new(instance1, instance3, 99, 1)])
        connection_explorer.stub(:discover_connections).with(instance2).and_return([Disco::Connection.new(instance2, instance3, 99, 2)])
        connection_explorer.stub(:discover_connections).with(instance3).and_return([])
      end

      it 'discovers all connections in the topology' do
        topology = explorer.discover_topology(%w[host1])
        topology.should include(Disco::Connection.new(instance1, instance2, 99, 1))
        topology.should include(Disco::Connection.new(instance1, instance3, 99, 1))
        topology.should include(Disco::Connection.new(instance2, instance3, 99, 2))
      end

      it 'does handles circular topologies' do
        connection_explorer.stub(:discover_connections).with(instance3).and_return([Disco::Connection.new(instance3, instance1, 99, 3)])
        topology = explorer.discover_topology(%w[host1])
        # expect no infinite loop
      end

      it 'explores the connections of each instance only once' do
        connection_explorer.should_receive(:discover_connections).with(instance3).once.and_return([])
        connection_explorer.stub(:discover_connections).with(instance2).and_return([Disco::Connection.new(instance2, instance3, 99, 2), Disco::Connection.new(instance2, instance3, 99, 3), Disco::Connection.new(instance2, instance3, 99, 4)])
        topology = explorer.discover_topology(%w[host1])
      end

      it 'removes duplicate connections to the same downstream port' do
        connection_explorer.stub(:discover_connections).with(instance1).and_return([
          Disco::Connection.new(instance1, instance2, 99, 1),
          Disco::Connection.new(instance1, instance2, 999, 1),
          Disco::Connection.new(instance1, instance2, 9999, 1),
          Disco::Connection.new(instance1, instance3, 99, 1)
        ])
        topology = explorer.discover_topology(%w[host1])
        topology.should_not include(Disco::Connection.new(instance1, instance2, 999, 1))
        topology.should_not include(Disco::Connection.new(instance1, instance2, 9999, 1))
      end

      context 'events' do
        it 'triggers an event before visiting an instance' do
          triggered = false
          explorer.on(:visit_instance) { |e| triggered = true }
          expect { explorer.discover_topology(%w[host1]) }.to change { triggered }.to(true)
        end

        it 'triggers an event after visiting an instance' do
          triggered = false
          explorer.on(:instance_visited) { |e| triggered = true }
          expect { explorer.discover_topology(%w[host1]) }.to change { triggered }.to(true)
        end
      end
    end
  end
end