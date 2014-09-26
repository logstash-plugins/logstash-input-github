# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"


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
    server = FTW::WebServer.new(@ip, @port) do |request, response|
	event = LogStash::Event.new
	event['message'] = request.read_body
        event['headers'] = request.headers
        decorate(event)
        output_queue << event
	response.status = 200
	response.body = "Accepted!"
    end
    server.run
  end # def run

end # class LogStash::Inputs::Websocket
