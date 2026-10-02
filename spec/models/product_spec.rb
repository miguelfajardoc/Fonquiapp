require "rails_helper"

RSpec.describe Product, type: :model do
  describe "identity" do
    it "is valid with a name and a price" do
      expect(build(:product)).to be_valid
    end

    it "is invalid without a name" do
      product = build(:product, name: "")
      expect(product).not_to be_valid
      expect(product.errors[:name]).to be_present
    end

    it "is invalid when the name is already taken" do
      create(:product, name: "Agua 500ml")
      duplicate = build(:product, name: "Agua 500ml")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end

  describe "price" do
    it "is stored at two decimal places" do
      product = create(:product, price: 12.5)
      expect(product.reload.price).to eq(BigDecimal("12.50"))
    end

    it "is invalid without a price" do
      product = build(:product, price: nil)
      expect(product).not_to be_valid
      expect(product.errors[:price]).to be_present
    end

    it "is invalid with a negative price" do
      product = build(:product, price: -1.00)
      expect(product).not_to be_valid
      expect(product.errors[:price]).to be_present
    end
  end

  describe "deletion" do
    it "can be deleted when nothing references it" do
      product = create(:product)
      expect { product.destroy }.to change(Product, :count).by(-1)
    end

    it "is blocked while a daily product order references it" do
      product = create(:product)
      create(:daily_product_order, product: product)

      expect(product.destroy).to be_falsey
      expect(product.errors[:base]).to be_present
      expect(Product.exists?(product.id)).to be(true)
    end
  end

  describe ".filter_by" do
    it "matches a name fragment ignoring case and accents, with % taken literally" do
      create(:product, name: "Queso Añejo")
      create(:product, name: "Crema de leche")
      create(:product, name: "Queso 100%")
      create(:product, name: "Queso 1000")

      expect(Product.filter_by(name: "ANEJO").pluck(:name)).to eq(["Queso Añejo"])
      expect(Product.filter_by(name: "100%").pluck(:name)).to eq(["Queso 100%"])
    end

    it "ignores a blank name" do
      create_list(:product, 2)

      expect(Product.filter_by(name: "").count).to eq(2)
    end
  end
end
