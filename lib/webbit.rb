# encoding: utf-8

require 'webbit-jars'


module Webbit
  import 'org.webbitserver.WebServer'
  import 'org.webbitserver.WebServers'
  import 'org.webbitserver.HttpHandler'
  import 'org.webbitserver.EventSourceHandler'
  import 'org.webbitserver.EventSourceMessage'
  import 'org.webbitserver.handler.StaticFileHandler'
  import 'org.webbitserver.handler.PathMatchHandler'

  module WebServer
    def start!
      start.get
    end
  end

  class Config
    attr_reader :server

    def initialize(port)
      @server = Webbit::WebServers.create_web_server(port)
    end

    def map(options)
      options.each do |key, handler_or_path|
        case key
        when :static
          @server.add(StaticFileHandler.new(handler_or_path))
        when String
          @server.add(key, handler_or_path)
        when Regexp
          @server.add(PathMatchHandler.new(to_java_regex(key), handler_or_path))
        else
          raise ArgumentError, "Unknown mapping: #{key} => #{handler_or_path}"
        end
      end
    end

    def to_java_regex(regex)
      java.util.regex.Pattern.compile(regex.to_s)
    end
  end

  def self.server(port, &block)
    config = Config.new(port)
    config.instance_eval(&block)
    config.server
  end

  def self.start_server(port, &block)
    s = server(port, &block)
    s.start.get
    s
  end
end
