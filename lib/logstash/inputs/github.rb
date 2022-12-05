# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require "json"
require "rack"

# Read events from github webhooks
class LogStash::Inputs::GitHub < LogStash::Inputs::Base
  config_name "github"

  # The ip to listen on
  config :ip, :validate => :string, :default => "0.0.0.0"

  # The port to listen on
  config :port, :validate => :number, :required => true

  # Your GitHub Secret Token for the webhook
  config :secret_token, :validate => :password, :required => false

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
        event = build_event_from_request(body, request.headers.to_hash)
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
  rescue Exception => original_exception
    # If our server crashes, it may not have cleaned up after itself;
    # since `FTW::WebServer#stop` is idempotent, make one last attempt
    # before propagating the original exception.
    @server && @server.stop rescue logger.error("Error while stopping FTW::WebServer", exception: $!.message, backtrace: $!.backtrace)

    raise original_exception
  end # def run

  def build_event_from_request(body, headers)
    begin
      data = JSON.parse(body)
      # The JSON specification defines single values as valid JSONs, it can be a string in double quotes,
      # a number, true or false or null. When the body is parsed, those values are transformed into its
      # corresponding types. When those types aren't a Hash (aka object),  it breaks the LogStash::Event
      # contract and crashes.
      if data.is_a?(::Hash)
        event = LogStash::Event.new(data)
      else
        event = LogStash::Event.new("message" => body, "tags" => "_invalidjsonobject")
      end
    rescue JSON::ParserError => e
      @logger.info("JSON parse failure. Falling back to plain-text", :error => e, :data => body)
      event = LogStash::Event.new("message" => body, "tags" => "_invalidjson")
    end
    event.set('headers', headers)
    return event
  end

  def verify_signature(event,body)
    # skip validation if we have no secret token
    return true unless @secret_token

    sign_header = event.get("[headers][x-hub-signature]")
    if sign_header
      hash = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), @secret_token.value, body)
      event.set("hash", hash)
      return true if Rack::Utils.secure_compare(hash, sign_header)
    end

    event.tag("_Invalid_Github_Message")
    return false
  end

  def stop
    @server && @server.stop
  end # def stop

end # class LogStash::Inputs::Github
