# Runs a CSV import from the uploaded `file` param and returns to the index with the result: a notice with the
# counts and, when rows failed, an alert listing them. A file that cannot be read becomes the only alert.
module CsvImporting
  extend ActiveSupport::Concern

  private

  def run_csv_import(importer_class, index_path:, notice_key:)
    show_csv_result(importer_class.new(params[:file]).call, notice_key)
    redirect_to index_path
  rescue CsvImport::InvalidFile => e
    redirect_to index_path, alert: e.message
  end

  def show_csv_result(result, notice_key)
    flash[:notice] = t(notice_key, created: result.created, updated: result.updated)
    flash[:alert] = result.failure_lines if result.failures.any?
  end
end
