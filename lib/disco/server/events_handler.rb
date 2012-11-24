# encoding: utf-8

module Disco
  module Server
    class EventsHandler
      include Webbit::EventSourceHandler

      def initialize(topology_explorer)
        @connections = []
        @broadcasts = []
        @topology_explorer = topology_explorer
        @topology_explorer.on(:start_exploration, &method(:start_exploration))
        @topology_explorer.on(:exploration_complete, &method(:exploration_complete))
        @topology_explorer.on(:visit_instance, &method(:visit_instance))
        @topology_explorer.on(:instance_visited, &method(:instance_visited))
      end

      def onOpen(connection)
        $stderr.puts('Connection open')
        @connections << connection
        send_message(connection, 'hello', '')
        $stderr.puts("Replaying #{@broadcasts.size} messages")
        @broadcasts.each do |event, message|
          send_message(connection, event, message)
        end
      end

      def onClose(connection)
        @connections.delete(connection)
      end

      private

      def broadcast(event, message)
        @broadcasts << [event, message]
        @connections.each do |connection|
          send_message(connection, event, message)
        end
      end

      def send_message(connection, event, message)
        message = Webbit::EventSourceMessage.new(message).event(event)
        connection.send(message)
      end

      def start_exploration(event)
        $stderr.puts('Resetting broadcasts')
        @broadcasts = []
      end

      def exploration_complete(event)
        $stderr.puts('Done!')
        broadcast('done', '{}')
      end

      def visit_instance(event)
        plain_event = {:host => event[:instance].to_h}
        broadcast('visit', plain_event.to_json)
        $stderr.puts("visit #{event[:instance].name}")
      end

      def instance_visited(event)
        connections = event[:connections].map do |c|
          {
            :upstream_host => c.upstream_instance.to_h,
            :downstream_host => c.downstream_instance.to_h,
            :upstream_port => c.upstream_port,
            :downstream_port => c.downstream_port
          }
        end
        plain_event = {
          :host => event[:instance].to_h,
          :connections => connections
        }
        broadcast('visited', plain_event.to_json)
        $stderr.puts("visited #{event[:instance].name}")
      end
    end
  end
end