# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require "json"



# Read events from github webhooks
class LogStash::Inputs::GitHub < LogStash::Inputs::Base
  config_name "github"
  milestone 1

  default :codec, "line"

  # The ip to listen on
  config :ip, :validate => :string, :default => "0.0.0.0"

  # The port to listen on
  config :port, :validate => :number, :required => true

  def register
    require "ftw"
  end # def register

  public
  def run(output_queue)
    # TODO(sissel): Implement server mode.
    @server = FTW::WebServer.new(@ip, @port) do |request, response|
        begin
          event = LogStash::Event.new(JSON.parse(request.read_body))
        rescue JSON::ParserError => e
          @logger.info("JSON parse failure. Falling back to plain-text", :error => e, :data => data)
          yield LogStash::Event.new("message" => data)
        end
        event['headers'] = request.headers.to_hash
        decorate(event)
        output_queue << event
        response.status = 200
        response.body = "Accepted!"
    end
    @server.run
  end # def run

  def teardown
    @server.stop
  end


end # class LogStash::Inputs::Websocket
