require "logstash/devutils/rspec/spec_helper"
require "logstash/plugin"
require "logstash/inputs/github"

describe  LogStash::Inputs::GitHub do

  let(:plugin) { LogStash::Plugin.lookup("input", "github").new( {"port" => 9999} ) }

  it "register without errors" do
    expect { plugin.register }.to_not raise_error
  end
end
