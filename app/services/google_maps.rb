# The one place that knows about Google Maps: the credentials holding the
# browser key (and optional map id) and the URL formats the app links to or
# embeds. Without a key, callers skip their maps instead of failing.
module GoogleMaps
  SEARCH_URL = "https://www.google.com/maps/search/".freeze
  EMBED_URL = "https://www.google.com/maps/embed/v1/place".freeze
  DEMO_MAP_ID = "DEMO_MAP_ID".freeze

  module_function

  def api_key
    Rails.application.credentials.dig(:google_maps, :api_key).presence
  end

  # Advanced markers need a map id; Google's demo id works until a real one is configured.
  def map_id
    Rails.application.credentials.dig(:google_maps, :map_id).presence || DEMO_MAP_ID
  end

  def search_url(query)
    "#{SEARCH_URL}?#{{ api: 1, query: query }.to_query}"
  end

  def embed_url(query)
    return if api_key.nil? || query.blank?

    "#{EMBED_URL}?#{{ key: api_key, q: query, language: "es", region: "CO" }.to_query}"
  end
end
