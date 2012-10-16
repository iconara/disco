require_relative '../spec_helper'


module Disco
  describe SsCommand do
    stubs :session

    let :command do
      described_class.new
    end

    let :data do
      File.readlines(__FILE__).drop_while { |line| !line.start_with?('__END') }.drop(1).join('')
    end

    describe '#connections' do
      let :connections do
        session.stub(:exec!).with('/usr/sbin/ss --tcp --numeric --info state established').and_return(data)
        command.connections(session)
      end

      it 'returns all downstream IP/port pairs' do
        connections.should include([57831, '::ffff:10.53.142.128', 5672, {'send' => '7.9Mbps'}])
        connections.should include([52785, '::ffff:10.48.178.144', 5672, {'send' => '247.1Mbps'}])
        connections.should include([22, '37.123.148.251', 44379, {'send' => '1.0Mbps'}])
      end

      it 'does not return connections to localhost' do
        connections.find { |_, host, _, _| host == '127.0.0.1' }.should be_nil
      end
    end
  end
end

__END__
Recv-Q Send-Q                          Local Address:Port                                            Peer Address:Port 
0      0                         ::ffff:10.51.34.249:57831                                   ::ffff:10.53.142.128:5672  
   cubic wscale:7,7 rto:210 rtt:7.375/10.75 ato:40 cwnd:5 ssthresh:4 send 7.9Mbps rcv_rtt:3.875 rcv_space:2114284
0      0                         ::ffff:10.51.34.249:52785                                   ::ffff:10.48.178.144:5672  
   cubic wscale:7,7 rto:204 rtt:1.875/0.75 ato:40 cwnd:40 ssthresh:199 send 247.1Mbps rcv_space:5840
0      48                               10.51.34.249:22                                            37.123.148.251:44379 
   cubic wscale:4,7 rto:237 rtt:34.125/3.5 ato:40 cwnd:3 ssthresh:31 send 1.0Mbps rcv_rtt:31 rcv_space:5792
0      0                                   127.0.0.1:4369                                               127.0.0.1:45503 
   cubic wscale:7,7 rto:205 rtt:5.625/6.5 ato:40 cwnd:3 send 69.9Mbps rcv_space:32768