require "csv"

# Shared reading for the CSV imports: checks the upload, decodes Excel-style files (UTF-8 with or without a
# BOM, or Windows-1252), matches headers ignoring case and spaces, and processes each row on its own so one
# bad row never stops the others. Subclasses declare REQUIRED_HEADERS and implement #import_row, returning
# :created or :updated, or raising RowError / ActiveRecord::RecordInvalid to fail that row.
class CsvImport
  MAX_BYTES = 2.megabytes
  MAX_LISTED_FAILURES = 20
  REQUIRED_HEADERS = [].freeze

  class InvalidFile < StandardError; end
  class RowError < StandardError; end

  Result = Struct.new(:created, :updated, :failures) do
    # "Fila N: motivo" for the first failures, plus a line saying how many more there were.
    def failure_lines
      lines = failures.first(MAX_LISTED_FAILURES).map do |line, message|
        I18n.t("csv_import.failure_line", line: line, message: message)
      end
      remaining = failures.size - MAX_LISTED_FAILURES
      lines << I18n.t("csv_import.more_failures", count: remaining) if remaining.positive?
      lines
    end
  end

  def initialize(file)
    @file = file
  end

  def call
    result = Result.new(0, 0, [])
    each_row { |row, line| process(row, line, result) }
    result
  rescue CSV::MalformedCSVError => e
    raise InvalidFile, I18n.t("csv_import.errors.malformed", detail: e.message)
  end

  private

  # Yields each data row with its line in the file. Blank lines are kept (and skipped in #process) so
  # csv.lineno matches the line the user sees.
  def each_row
    csv = CSV.new(decode(read_upload), headers: true, header_converters: ->(header) { header.to_s.strip.downcase })
    first_row = csv.shift
    check_headers!(csv.headers)
    yield first_row, csv.lineno if first_row
    csv.each { |row| yield row, csv.lineno }
  end

  def read_upload
    raise InvalidFile, I18n.t("csv_import.errors.missing_file") unless @file.respond_to?(:read)
    raise InvalidFile, I18n.t("csv_import.errors.too_large") if @file.size > MAX_BYTES

    @file.read
  end

  def decode(bytes)
    text = bytes.dup.force_encoding(Encoding::UTF_8)
    text = bytes.dup.force_encoding(Encoding::Windows_1252).encode(Encoding::UTF_8) unless text.valid_encoding?
    text.delete_prefix("﻿")
  end

  def check_headers!(headers)
    missing = self.class::REQUIRED_HEADERS - Array(headers)
    return if missing.empty?

    raise InvalidFile, I18n.t("csv_import.errors.missing_columns", columns: missing.join(", "))
  end

  def process(row, line, result)
    return if row.fields.all?(&:blank?)

    result[import_row(row) == :updated ? :updated : :created] += 1
  rescue RowError => e
    result.failures << [line, e.message]
  rescue ActiveRecord::RecordInvalid => e
    result.failures << [line, e.record.errors.full_messages.to_sentence]
  end

  def value(row, column)
    row[column].to_s.strip.presence
  end

  def require_values!(row, *columns)
    missing = columns.reject { |column| value(row, column) }
    raise RowError, I18n.t("csv_import.errors.missing_values", columns: missing.join(", ")) if missing.any?
  end

  # Exact match ignoring case, accents and surrounding spaces, for find-or-create lookups by name.
  def named(scope, column, name)
    scope.where("lower(unaccent(#{column})) = lower(unaccent(?))", name)
  end
end
