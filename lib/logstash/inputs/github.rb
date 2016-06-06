# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require "json"

# Read events from github webhooks
class LogStash::Inputs::GitHub < LogStash::Inputs::Base
  config_name "github"

  # The ip to listen on
  config :ip, :validate => :string, :default => "0.0.0.0"

  # The port to listen on
  config :port, :validate => :number, :required => true

  # Your GitHub Secret Token for the webhook
  config :secret_token, :validate => :string, :required => false

  # If Secret is defined, we drop the events that don't match.
  # Otherwise, we'll just add an invalid tag
  config :drop_invalid, :validate => :boolean, :default => false

  def register
    require "ftw"
  end # def register

  public
  def run(output_queue)
    @server = FTW::WebServer.new(@ip, @port) do |request, response|
        body = request.read_body
        event = build_event_from_request(body, request.headers_.to_hash)
        valid_event = verify_signature(event,body)
        if !valid_event && @drop_invalid
          @logger.info("Dropping invalid Github message")
        else
          decorate(event)
          output_queue << event
        end
        response.status = 200
        response.body = "Accepted!"
    end
    @server.run
  end # def run

  def build_event_from_request(body, headers)
    begin
      event = LogStash::Event.new(JSON.parse(body))
    rescue JSON::ParserError => e
      @logger.info("JSON parse failure. Falling back to plain-text", :error => e, :data => body)
      event = LogStash::Event.new("message" => body, "tags" => "_invalidjson")
    end
    event.set('headers', headers)
    return event
  end

  def verify_signature(event,body)
    is_valid = true
    sign_header = event.get("[headers][x-hub-signature]")
    if @secret_token && sign_header
      hash = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), @secret_token, body)
      event.set("hash", hash)
      if not Rack::Utils.secure_compare(hash, sign_header)
        event.tag("_Invalid_Github_Message")
        is_valid = false
      end
    end
    return is_valid
  end

  def close
    @server.stop
  end # def close

end # class LogStash::Inputs::Github
