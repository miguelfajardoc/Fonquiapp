require "rails_helper"

RSpec.describe User, type: :model do
  it "normalizes the email address by stripping spaces and downcasing" do
    user = create(:user, email_address: "  Staff@Example.COM ")

    expect(user.email_address).to eq("staff@example.com")
  end

  it "rejects a duplicate email address" do
    create(:user, email_address: "staff@example.com")

    expect { create(:user, email_address: "STAFF@example.com") }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "authenticates only with the right password" do
    user = create(:user, password: "123456")

    expect(user.authenticate("123456")).to eq(user)
    expect(user.authenticate("otra")).to be(false)
  end

  it "destroys its sessions along with it" do
    user = create(:user)
    user.sessions.create!

    expect { user.destroy }.to change(Session, :count).by(-1)
  end
end
