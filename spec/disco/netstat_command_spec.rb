require_relative '../spec_helper'


module Disco
  describe NetstatCommand do
    stubs :session

    let :port_mapper do
      pm = stub(:port_mapper)
      pm.stub(:numeric_port) { |s| s.to_i }
      pm
    end

    let :command do
      described_class.new(port_mapper)
    end

    let :data do
      File.readlines(__FILE__).drop_while { |line| !line.start_with?('__END') }.drop(1).join("\n")
    end

    describe '#connections' do
      let :connections do
        session.stub(:exec!).with('netstat --tcp --numeric').and_return(data)
        command.connections(session)
      end

      it 'returns all downstream IP/port pairs' do
        connections.should include([46191, '10.39.13.213', 5005])
        connections.should include([22, '80.252.215.26', 2445])
        connections.should include([5672, '::ffff:10.51.34.249', 57188])
      end

      it 'does not return nil' do
        connections.should_not include([nil, nil])
      end
    end
  end
end

__END__
Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address               Foreign Address             State      
tcp        0      0 10.53.142.128:46191         10.39.13.213:5005           TIME_WAIT   
tcp        0      0 10.53.142.128:55672         80.252.215.26:2196          ESTABLISHED 
tcp        0      0 127.0.0.1:45503             127.0.0.1:4369              ESTABLISHED 
tcp        0      0 127.0.0.1:36597             127.0.0.1:55672             TIME_WAIT   
tcp        0      0 127.0.0.1:36582             127.0.0.1:55672             TIME_WAIT   
tcp        0      0 127.0.0.1:36591             127.0.0.1:55672             TIME_WAIT   
tcp        0      0 127.0.0.1:36596             127.0.0.1:55672             TIME_WAIT   
tcp        0      0 127.0.0.1:36589             127.0.0.1:55672             TIME_WAIT   
tcp        0      0 127.0.0.1:36573             127.0.0.1:55672             TIME_WAIT   
tcp        0      0 10.53.142.128:22            80.252.215.26:2445          ESTABLISHED 
tcp        0      0 10.53.142.128:53437         10.49.114.115:58426         ESTABLISHED 
tcp        1      0 10.53.142.128:39345         169.254.169.254:80          CLOSE_WAIT  
tcp        0      0 127.0.0.1:4369              127.0.0.1:45503             ESTABLISHED 
tcp        0      0 127.0.0.1:36583             127.0.0.1:55672             TIME_WAIT   
tcp        0      0 10.53.142.128:36646         184.106.28.84:443           ESTABLISHED 
tcp        0      0 ::ffff:10.53.142.128:5672   ::ffff:10.51.34.249:57188   ESTABLISHED 
