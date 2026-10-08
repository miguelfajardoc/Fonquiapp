require "rails_helper"

RSpec.describe GoogleMaps do
  describe ".search_url" do
    it "builds an encoded Google Maps search link" do
      expect(described_class.search_url("Calle 22 # 1-78, Bogotá"))
        .to eq("https://www.google.com/maps/search/?api=1&query=Calle+22+%23+1-78%2C+Bogot%C3%A1")
    end
  end

  describe ".embed_url" do
    it "builds an Embed API url carrying the key, the query and the Colombian region" do
      url = URI(described_class.embed_url("4.711,-74.0721"))

      expect("#{url.scheme}://#{url.host}#{url.path}").to eq(GoogleMaps::EMBED_URL)
      expect(Rack::Utils.parse_query(url.query))
        .to eq("key" => "test-maps-key", "q" => "4.711,-74.0721", "language" => "es", "region" => "CO")
    end

    it "returns nil without a key or without a query" do
      expect(described_class.embed_url("")).to be_nil

      allow(described_class).to receive(:api_key).and_return(nil)
      expect(described_class.embed_url("Calle 1")).to be_nil
    end
  end

  describe ".map_id" do
    it "falls back to Google's demo map id when none is configured" do
      allow(Rails.application.credentials).to receive(:dig).and_call_original
      allow(Rails.application.credentials).to receive(:dig).with(:google_maps, :map_id).and_return(nil)

      expect(described_class.map_id).to eq("DEMO_MAP_ID")
    end
  end
end
