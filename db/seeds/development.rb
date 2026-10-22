# Sample data for development only, loaded from db/seeds.rb. Never runs in production: it uses Faker and
# regenerates route stops, default quantities and pending products with delete_all.

CLIENT_NAME_PREFIXES = %w[Salsamentaria Tienda Autoservicio Supermercado Distribuidora].freeze
CLIENT_NAME_SUFFIXES = ["La Esperanza", "El Paisa", "San José", "La 42", "Doña Rosa", "La Colonial", "Don Pedro",
                        "Santa Fe"].freeze
STREET_TYPES = %w[Calle Carrera Avenida].freeze

def random_client_name
  "#{CLIENT_NAME_PREFIXES.sample} #{CLIENT_NAME_SUFFIXES.sample}"
end

def random_bogota_address
  "#{STREET_TYPES.sample} #{rand(1..170)} # #{rand(1..99)}-#{rand(1..99)}, Bogotá y alrededores"
end

# --- Zones ------------------------------------------------------------------
zones = %w[Bosa Soacha Kennedy].map { |name| Zone.find_or_create_by!(name: name) }

# --- Products -----------------------------------------------------------
products = ["Queso", "Suero", "Mantequilla", "Crema de leche"].map do |name|
  Product.find_or_create_by!(name: name) { |product| product.price = rand(5_000..30_000) }
end

# --- Clients (2 per zone, topped up rather than re-keyed since names are random) ---
zones.each do |zone|
  (2 - zone.clients.count).times do
    zone.clients.create!(
      name: random_client_name,
      address: random_bogota_address,
      phone: Faker::PhoneNumber.phone_number
    )
  end
end
clients = Client.all.to_a

# --- Routes ---------------------------------------------------------------
routes = zones.flat_map do |zone|
  (1..2).map { |n| Route.find_or_create_by!(zone: zone, name: "Ruta #{n}") }
end

# --- Route stops (regenerated every run) -----------------------------------
RouteStop.delete_all
routes.each do |route|
  route.zone.clients.shuffle.each { |client| route.route_stops.create!(client: client) }
end

# --- Default product quantities per route (regenerated every run) ------------
DefaultProductQuantity.delete_all
routes.each do |route|
  products.sample(rand(2..4)).each do |product|
    route.default_product_quantities.create!(product: product, quantity: rand(5..30))
  end
end

# --- Pending products (regenerated every run) --------------------------
PendingProduct.delete_all
%i[delivered delivered pending pending canceled].shuffle.each do |state|
  client = clients.sample
  PendingProduct.create!(
    product: products.sample,
    client: client,
    zone: client.zone,
    quantity: rand(1..5),
    state: state
  )
end

# No seeds for DailyProductOrder.
