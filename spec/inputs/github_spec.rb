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

  describe "verify webhook signature if token provided" do
    let(:plugin) { LogStash::Plugin.lookup("input", "github").new( {"port" => 9999, "secret_token" => "my_secret"} ) }
    let(:body) {IO.read("spec/fixtures/event_create.json")}
    let(:headers) { {"x-hub-signature" => "hash"} }
    let(:event) {plugin.build_event_from_request(body,headers)}
    let(:hash) { "sha1=43b113fc453c47f1cd4d5b4ded2985581c00a715" }

    it "reject event without signature" do
      event.set('headers',{})
      expect(plugin.verify_signature(event,body)).to eq(false)
      expect(event.get("hash")).to be_nil
      expect(event.get("tags")).to eq(["_Invalid_Github_Message"])
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

  describe "don't validate webhook if token missing" do
    let(:plugin) { LogStash::Plugin.lookup("input", "github").new( {"port" => 9999} ) }
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

    it "accept event with invalid signature" do
      event.set('headers',{"x-hub-signature" => "invalid"})
      expect(plugin.verify_signature(event,body)).to eq(true)
      expect(event.get("hash")).to be_nil
      expect(event.get("tags")).to be_nil
    end

    it "accept event with valid signature" do
      event.set('headers', {"x-hub-signature" => hash})
      expect(plugin.verify_signature(event,body)).to eq(true)
      expect(event.get("hash")).to be_nil
      expect(event.get("tags")).to be_nil
    end

  end

  describe "verify event builder" do
    let(:plugin) { LogStash::Plugin.lookup("input", "github").new( {"port" => 9999} ) }
    let(:body) {"{}"}
    let(:event) {plugin.build_event_from_request(body, {})}

    context 'when request body is a minimal JSON value' do
      let(:body) {"123"}
      it 'should add the body string into the message field and tag' do
        expect(event.get("message")).to eq("123")
        expect(event.get("tags")).to eq("_invalidjsonobject")
      end
    end

    context 'when request body is a JSON object' do
      let(:body) {'{"action": "create"}'}
      it 'should parse the body' do
        expect(event.get("action")).to eq("create")
      end
    end
  end

  describe 'graceful shutdown' do
    context 'when underlying webserver crashes' do

      # Stubbing out our FTW::WebServer allows us to force it to raise an exception when we try to run it.
      let(:mock_webserver_class) { double('FTW::WebServer::class').as_null_object }
      let(:mock_webserver) { double('FTW::WebServer').as_null_object }
      before(:each) do
        stub_const('FTW::WebServer', mock_webserver_class)
        allow(mock_webserver_class).to receive(:new).and_return(mock_webserver)
        expect(mock_webserver).to receive(:run).and_raise('testing: intentional uncaught exception')
      end

      it 'makes an attempt to stop the webserver' do
        expect(mock_webserver).to receive(:stop)

        plugin.run([]) rescue nil
      end

      it 'propagates the original exception' do
        expect do
          plugin.run([])
        end.to raise_exception('testing: intentional uncaught exception')
      end

      context 'and an attempt to stop the webserver also crashes' do
        let(:mock_logger) { double('Logger').as_null_object }
        before(:each) do
          allow(plugin).to receive(:logger).and_return(mock_logger)
          allow(mock_webserver).to receive(:stop).and_raise('yo dawg')
        end

        it 'logs helpfully' do
          expect(mock_logger).to receive(:error).with("Error while stopping FTW::WebServer",
                                                      exception: 'yo dawg', backtrace: instance_of(Array))

          plugin.run([]) rescue nil
        end

        it 'propagates the original exception' do
          expect do
            plugin.run([])
          end.to raise_exception('testing: intentional uncaught exception')
        end
      end
    end
  end
end
