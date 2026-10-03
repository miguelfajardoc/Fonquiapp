# Helpers for request specs of filtered, paginated index pages: each page wraps
# its table in a Turbo Frame and renders an empty-state row with a colspan.
module FilteredIndexHelpers
  def frame_rows(frame_id)
    response.parsed_body.css("turbo-frame##{frame_id} tbody tr").reject { |row| row.at_css("td[colspan]") }
  end

  # The text of one column for every listed row, in order.
  def frame_column(frame_id, index)
    frame_rows(frame_id).map { |row| row.css("td")[index].text.strip }
  end

  def frame_headers(frame_id)
    response.parsed_body.css("turbo-frame##{frame_id} thead th").map { |th| th.text.strip }
  end

  def pagination_nav(frame_id)
    response.parsed_body.at_css("turbo-frame##{frame_id} nav.pagy")
  end

  def next_page_query(frame_id)
    link = pagination_nav(frame_id).at_css("a[rel='next']")
    Rack::Utils.parse_query(URI.parse(link["href"]).query)
  end

  # Turbo Stream responses are not parsed by `response.parsed_body`; parse them as an HTML fragment.
  def stream_body
    Nokogiri::HTML5.fragment(response.body)
  end

  def clear_filters_link
    response.parsed_body.css("a").find { |a| a.text.strip == I18n.t("shared.filters.clear") }
  end
end

RSpec.configure { |config| config.include FilteredIndexHelpers, type: :request }
