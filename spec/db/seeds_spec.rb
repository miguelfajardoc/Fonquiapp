require "rails_helper"

RSpec.describe "db/seeds.rb" do
  let(:staff_email) { "lacteosfonquilacpc@gmail.com" }

  def run_seeds(env:, admin_password: nil)
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new(env))
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_PASSWORD").and_return(admin_password)
    load Rails.root.join("db/seeds.rb")
  end

  def staff
    User.find_by(email_address: staff_email)
  end

  describe "staff account outside production" do
    it "creates the staff account once with the temporary password" do
      run_seeds(env: "test")

      expect(staff.authenticate("123456")).to be_truthy
    end

    it "keeps a changed password when re-seeding" do
      create(:user, email_address: staff_email, password: "changed-pass")

      run_seeds(env: "test")

      expect(staff.authenticate("changed-pass")).to be_truthy
    end
  end

  describe "staff account in production" do
    it "creates the staff account with ADMIN_PASSWORD" do
      run_seeds(env: "production", admin_password: "s3cret-pass")

      expect(staff.authenticate("s3cret-pass")).to be_truthy
      expect(staff.authenticate("123456")).to be_falsey
    end

    it "fails naming ADMIN_PASSWORD and creates no user when it is missing" do
      expect { run_seeds(env: "production") }
        .to raise_error(SystemExit).and output(/ADMIN_PASSWORD/).to_stderr

      expect(staff).to be_nil
    end

    it "treats a blank ADMIN_PASSWORD as missing" do
      expect { run_seeds(env: "production", admin_password: " ") }
        .to raise_error(SystemExit).and output(/ADMIN_PASSWORD/).to_stderr

      expect(staff).to be_nil
    end

    it "needs no ADMIN_PASSWORD once the staff account exists" do
      create(:user, email_address: staff_email, password: "changed-pass")

      expect { run_seeds(env: "production") }.not_to raise_error

      expect(staff.authenticate("changed-pass")).to be_truthy
    end
  end

  describe "sample data" do
    it "preserves real data and creates no sample records outside development" do
      create(:user, email_address: staff_email)
      route_stop = create(:route_stop)
      default_quantity = create(:default_product_quantity)
      pending_product = create(:pending_product)
      counts = [Zone.count, Product.count, Client.count]

      run_seeds(env: "production")

      expect(RouteStop.exists?(route_stop.id)).to be(true)
      expect(DefaultProductQuantity.exists?(default_quantity.id)).to be(true)
      expect(PendingProduct.exists?(pending_product.id)).to be(true)
      expect([Zone.count, Product.count, Client.count]).to eq(counts)
    end

    it "loads sample zones, products, clients, routes and route stops in development" do
      run_seeds(env: "development")

      expect(Zone.pluck(:name)).to include("Bosa", "Soacha", "Kennedy")
      expect(Product.count).to be >= 4
      expect(Client.count).to be >= 6
      expect(Route.count).to be >= 6
      expect(RouteStop.count).to be > 0
    end
  end
end
