class ProductsController < ApplicationController
  include CsvImporting

  FILTER_KEYS = %i[name].freeze

  before_action :set_product, only: %i[edit update destroy]

  def index
    @filters = params.slice(*FILTER_KEYS).permit(*FILTER_KEYS).to_h
    @pagy, @products = pagy(:offset, Product.filter_by(@filters).order(:name))
  end

  def new
    @product = Product.new
  end

  def edit; end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to products_path, notice: t("products.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @product.update(product_params)
      redirect_to products_path, notice: t("products.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def import
    run_csv_import(ProductCsvImport, index_path: products_path, notice_key: "products.flash.imported")
  end

  def destroy
    if @product.destroy
      redirect_to products_path, notice: t("products.flash.deleted")
    else
      redirect_to products_path, alert: @product.errors.full_messages.to_sentence
    end
  end

  private

  def set_product
    @product = Product.find(params.expect(:id))
  end

  def product_params
    params.expect(product: %i[name price])
  end
end
