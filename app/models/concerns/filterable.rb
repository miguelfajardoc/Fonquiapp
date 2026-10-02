# Applies a set of filter params to a model's relation by calling one
# `filter_by_<key>` scope per non-blank value. Callers pass only permitted
# keys, so each including model decides exactly which filters it supports.
module Filterable
  extend ActiveSupport::Concern

  class_methods do
    def filter_by(filters)
      filters.to_h.compact_blank.reduce(all) do |scope, (key, value)|
        scope.public_send(:"filter_by_#{key}", value)
      end
    end

    # Contains match ignoring case and accents. `column_sql` is a literal
    # written in the model, never user input; typed text is matched literally.
    def where_unaccent_contains(column_sql, text)
      where("unaccent(#{column_sql}) ILIKE unaccent(?)", "%#{sanitize_sql_like(text)}%")
    end
  end
end
