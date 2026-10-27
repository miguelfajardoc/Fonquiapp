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

  describe ".coordinates_from_url" do
    it "reads the viewport coordinates of a full link" do
      expect(described_class.coordinates_from_url("https://www.google.com/maps/place/Tienda/@4.7110,-74.0721,17z"))
        .to eq([BigDecimal("4.711"), BigDecimal("-74.0721")])
    end

    it "prefers the place pin over the viewport" do
      url = "https://www.google.com/maps/place/Tienda/@4.7,-74.0,17z/data=!3m1!4b1!4m6!3m5!8m2!3d4.65!4d-74.1"

      expect(described_class.coordinates_from_url(url)).to eq([BigDecimal("4.65"), BigDecimal("-74.1")])
    end

    it "accepts Google's country domains" do
      expect(described_class.coordinates_from_url("https://www.google.com.co/maps/@4.7110,-74.0721,17z"))
        .to eq([BigDecimal("4.711"), BigDecimal("-74.0721")])
    end

    it "reads query, q and ll parameters" do
      %w[query q ll].each do |key|
        url = "https://www.google.com/maps/search/?api=1&#{key}=4.711%2C-74.0721"

        expect(described_class.coordinates_from_url(url)).to eq([BigDecimal("4.711"), BigDecimal("-74.0721")])
      end
    end

    it "follows a short link's redirect and reads the long link" do
      allow(described_class).to receive(:redirect_location)
        .and_return("https://www.google.com/maps/place/Tienda/data=!3d4.65!4d-74.1")

      expect(described_class.coordinates_from_url("https://maps.app.goo.gl/AbC123"))
        .to eq([BigDecimal("4.65"), BigDecimal("-74.1")])
      expect(described_class).to have_received(:redirect_location).once
    end

    it "stops after three short-link redirects" do
      allow(described_class).to receive(:redirect_location).and_return("https://maps.app.goo.gl/again")

      expect(described_class.coordinates_from_url("https://maps.app.goo.gl/AbC123")).to be_nil
      expect(described_class).to have_received(:redirect_location).exactly(3).times
    end

    it "returns nil when the short link cannot be followed" do
      allow(Net::HTTP).to receive(:start).and_raise(Net::OpenTimeout)

      expect(described_class.coordinates_from_url("https://maps.app.goo.gl/AbC123")).to be_nil
    end

    it "returns nil for links without coordinates, out-of-range values, other sites or garbage, without requests" do
      allow(Net::HTTP).to receive(:start)

      ["https://www.google.com/maps/place/Tienda", "https://maps.google.com/?q=95,-74",
       "https://example.com/@4.7,-74.0", "https://example.com/x", "not a url", ""].each do |url|
        expect(described_class.coordinates_from_url(url)).to(be_nil, url)
      end
      expect(Net::HTTP).not_to have_received(:start)
    end
  end
end
