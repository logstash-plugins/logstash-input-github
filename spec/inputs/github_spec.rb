require "logstash/devutils/rspec/spec_helper"
require "logstash/plugin"
require "logstash/inputs/github"

describe  LogStash::Inputs::GitHub do

  let(:plugin) { LogStash::Plugin.lookup("input", "github").new( {"port" => 9999} ) }

  it "register without errors" do
    expect { plugin.register }.to_not raise_error
  end

  describe "building Logstash event from webhook" do
    let(:body) {IO.read("spec/fixtures/event_create.json")}
    let(:headers) { {"fake_header" => "fake_value"} }
    let(:event) {plugin.build_event_from_request(body,headers)}

    it "initialize event from webhook body" do
      JSON.parse(body).each do |k,v|
        expect(event.get(k)).to eq(v)
      end
    end

    it "copy webhook http headers to event[headers]" do
      expect(event.get('headers')).to eq (headers)
    end
  end

  describe "verify webhook signature" do
    let(:plugin) { LogStash::Plugin.lookup("input", "github").new( {"port" => 9999, "secret_token" => "my_secret"} ) }
    let(:body) {IO.read("spec/fixtures/event_create.json")}
    let(:headers) { {"x-hub-signature" => "hash"} }
    let(:event) {plugin.build_event_from_request(body,headers)}
    let(:hash) { "sha1=43b113fc453c47f1cd4d5b4ded2985581c00a715" }

    it "accept event without signature" do
      event.set('headers',{})
      expect(plugin.verify_signature(event,body)).to eq(true)
      expect(event.get("hash")).to be_nil
      expect(event.get("tags")).to be_nil
    end

    it "reject event with invalid signature" do
      event.set('headers',{"x-hub-signature" => "invalid"})
      expect(plugin.verify_signature(event,body)).to eq(false)
      expect(event.get("hash")).to eq(hash)
      expect(event.get("tags")).to eq(["_Invalid_Github_Message"])
    end

    it "accept event with valid signature" do
      event.set('headers', {"x-hub-signature" => hash})
      expect(plugin.verify_signature(event,body)).to eq(true)
      expect(event.get("hash")).to eq(hash)
      expect(event.get("tags")).to be_nil
    end

  end
end
