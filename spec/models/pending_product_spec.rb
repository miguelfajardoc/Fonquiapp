require "rails_helper"

RSpec.describe PendingProduct, type: :model do
  describe "creation" do
    it "is valid with a quantity and the three references" do
      expect(build(:pending_product)).to be_valid
    end

    it "defaults its state to pending" do
      expect(PendingProduct.new.state).to eq("pending")
      expect(create(:pending_product).state).to eq("pending")
    end
  end

  describe "state lifecycle" do
    it "moves between pending, delivered and canceled" do
      pending_product = create(:pending_product)

      pending_product.update!(state: :delivered)
      expect(pending_product.reload).to be_delivered

      pending_product.update!(state: :canceled)
      expect(pending_product.reload).to be_canceled
    end
  end

  describe "validations" do
    it "is invalid with a non-positive quantity" do
      [0, -3].each do |value|
        record = build(:pending_product, quantity: value)
        expect(record).not_to be_valid
        expect(record.errors[:quantity]).to be_present
      end
    end

    it "is invalid with a non-integer quantity" do
      record = build(:pending_product, quantity: 2.5)
      expect(record).not_to be_valid
      expect(record.errors[:quantity]).to be_present
    end

    it "is invalid without a product, client or zone" do
      record = PendingProduct.new(quantity: 1)
      expect(record).not_to be_valid
      expect(record.errors[:product]).to be_present
      expect(record.errors[:client]).to be_present
      expect(record.errors[:zone]).to be_present
    end
  end

  describe "referential integrity" do
    it "cannot be created with a product that does not exist" do
      record = build(:pending_product)
      record.product_id = 0
      expect { record.save(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "allows several pending products for the same product+client+zone" do
      first = create(:pending_product)
      second = build(:pending_product, product: first.product, client: first.client, zone: first.zone)
      expect(second).to be_valid
    end

    it "blocks deleting a zone it references" do
      pending_product = create(:pending_product)
      zone = pending_product.zone

      expect(zone.destroy).to be_falsey
      expect(zone.errors[:base]).to be_present
      expect(Zone.exists?(zone.id)).to be(true)
    end
  end
end
