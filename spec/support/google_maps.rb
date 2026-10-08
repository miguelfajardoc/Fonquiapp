# Tests never render the real Google Maps key from credentials; examples that
# need the no-key behavior stub GoogleMaps.api_key to nil themselves.
RSpec.configure do |config|
  config.before do
    allow(GoogleMaps).to receive(:api_key).and_return("test-maps-key")
  end
end
