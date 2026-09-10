require "rails_helper"

# Guard against accidentally reverting to another adapter (e.g. SQLite) and
# confirms the test database is actually reachable in CI.
RSpec.describe "database connection" do
  it "uses the PostgreSQL adapter" do
    expect(ActiveRecord::Base.connection.adapter_name).to eq("PostgreSQL")
  end

  it "can execute a query" do
    expect(ActiveRecord::Base.connection.select_value("SELECT 1")).to eq(1)
  end
end
