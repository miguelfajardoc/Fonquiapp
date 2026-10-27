require "rails_helper"

RSpec.describe ProductCsvImport do
  def import(content)
    described_class.new(StringIO.new(content.b)).call
  end

  it "creates a new product with its price" do
    result = import("name,price\nArequipe,8500\n")

    expect(result.created).to eq(1)
    expect(Product.find_by!(name: "Arequipe").price).to eq(BigDecimal("8500"))
  end

  it "updates the price of an existing product matched ignoring case and accents, keeping its name" do
    product = create(:product, name: "Piña Colada", price: 10_000)

    result = import("name,price\npina colada,12000.5\n")

    expect([result.created, result.updated]).to eq([0, 1])
    expect(product.reload).to have_attributes(name: "Piña Colada", price: BigDecimal("12000.50"))
    expect(Product.count).to eq(1)
  end

  it "matches headers ignoring case and order, and ignores other columns" do
    import("Price, NAME ,notes\n2500,Queso,fresco\n")

    expect(Product.find_by!(name: "Queso").price).to eq(BigDecimal("2500"))
  end

  it "fails rows with a missing name or price" do
    result = import("name,price\n,100\nQueso,\n")

    expect(result.failures).to eq([[2, "falta name"], [3, "falta price"]])
    expect(Product.count).to eq(0)
  end

  it "fails rows with an invalid price" do
    result = import(%(name,price\nA,-5\nB,abc\nC,"12.500,00"\n))

    expect(result.failures.map(&:first)).to eq([2, 3, 4])
    expect(result.failures.map(&:last)).to all(start_with("precio inválido"))
    expect(Product.count).to eq(0)
  end

  it "reports created and updated rows together and keeps going after a failure" do
    create(:product, name: "Queso", price: 1)

    result = import("name,price\nNuevo,10\nQueso,20\nMalo,\n")

    expect([result.created, result.updated, result.failures]).to eq([1, 1, [[4, "falta price"]]])
  end

  it "rejects a file without the price column" do
    expect { import("name\nQueso\n") }.to raise_error(CsvImport::InvalidFile, /price/)
  end
end
