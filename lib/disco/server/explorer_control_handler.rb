# encoding: utf-8

module Disco
  module Server
    class ExplorerControlHandler
      def initialize(*args)
        @topology_explorer, @executor = args
        @current_disco = nil
      end

      def handleHttpRequest(request, response, control)
        if request.method == 'POST'
          if @current_disco && !@current_disco.done?
            response.status(409)
          else
            request_obj = JSON.parse(request.body)
            seed = request_obj && request_obj['seed']
            if seed && !seed.strip.empty?
              @current_disco = @executor.submit do
                $stderr.puts("Starting discovery from #{seed}")
                begin
                  @topology_explorer.discover_topology([seed])
                rescue => e
                  $stderr.puts("AARGH: #{e.message} (#{e.class.name})")
                end
              end
              response.status(200)
            else
              response.status(400)
            end
          end
        else
          response.status(405)
        end
        response.end
      end
    end
  end
end