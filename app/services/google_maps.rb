require "net/http"

# The one place that knows about Google Maps: the credentials holding the
# browser key (and optional map id), the URL formats the app links to or
# embeds, and reading coordinates back out of a Google Maps link. Without a
# key, callers skip their maps instead of failing.
module GoogleMaps
  SEARCH_URL = "https://www.google.com/maps/search/".freeze
  EMBED_URL = "https://www.google.com/maps/embed/v1/place".freeze
  DEMO_MAP_ID = "DEMO_MAP_ID".freeze
  MAX_REDIRECTS = 3
  TIMEOUT_SECONDS = 3
  NUMBER = /-?\d+(?:\.\d+)?/
  PIN_PATTERN = /!3d(#{NUMBER})!4d(#{NUMBER})/
  VIEWPORT_PATTERN = /@(#{NUMBER}),(#{NUMBER})/
  PAIR_PATTERN = /\A\s*(#{NUMBER})\s*,\s*(#{NUMBER})\s*\z/
  COORDINATE_PARAMS = %w[query q ll].freeze
  GOOGLE_HOST = /(\A|\.)google\.[a-z]{2,3}(\.[a-z]{2})?\z/

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

  # [latitude, longitude] from a full Google Maps link, or from a short link after following its redirects.
  # Returns nil when the link holds no valid coordinates or the short link cannot be followed.
  def coordinates_from_url(url)
    uri = parse_url(url)
    return if uri.nil?

    uri = parse_url(resolve_short_link(uri)) if short_link?(uri)
    coordinates_in(uri) if uri && google_host?(uri)
  end

  # Follows a short link's redirects without leaving the short-link hosts: the long link it ends on is
  # returned for parsing, never requested.
  def resolve_short_link(uri)
    MAX_REDIRECTS.times do
      location = redirect_location(uri)
      return if location.nil?

      uri = URI.join(uri, location)
      return uri.to_s unless short_link?(uri)
    end
    nil
  rescue StandardError
    nil
  end

  def redirect_location(uri)
    options = { use_ssl: uri.scheme == "https", open_timeout: TIMEOUT_SECONDS, read_timeout: TIMEOUT_SECONDS }
    response = Net::HTTP.start(uri.host, uri.port, **options) { |http| http.request_get(uri.request_uri) }
    response["location"] if response.is_a?(Net::HTTPRedirection)
  end

  def parse_url(url)
    uri = URI.parse(url.to_s.strip)
    uri if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end

  def short_link?(uri)
    host = uri.host.downcase
    host == "maps.app.goo.gl" || (host == "goo.gl" && uri.path.start_with?("/maps"))
  end

  def google_host?(uri)
    uri.host.downcase.match?(GOOGLE_HOST)
  end

  def coordinates_in(uri)
    text = CGI.unescape(uri.to_s)
    match = text.match(PIN_PATTERN) || text.match(VIEWPORT_PATTERN)
    valid_coordinates(match ? match.captures : coordinate_param(uri))
  end

  def coordinate_param(uri)
    params = Rack::Utils.parse_query(uri.query.to_s)
    COORDINATE_PARAMS.each do |key|
      match = params[key].to_s.match(PAIR_PATTERN)
      return [match[1], match[2]] if match
    end
    nil
  end

  def valid_coordinates(pair)
    return if pair.nil?

    latitude, longitude = pair.map { |number| BigDecimal(number) }
    [latitude, longitude] if latitude.abs <= 90 && longitude.abs <= 180
  end
end
