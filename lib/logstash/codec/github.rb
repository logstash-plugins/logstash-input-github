# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/spool"

# This is the base class for logstash codecs.
class LogStash::Codecs::GitHub < LogStash::Codecs::Spool
  config_name "github"
  milestone 1

  public
  def decode(data)
      # Seperate the headers from the body
      headers, body = data.split("\r\n\r\n")
      yield LogStash::Event.new("headers" => headers, "message" => body)
  end # def decode

end # class LogStash::Codecs::CloudTrail
