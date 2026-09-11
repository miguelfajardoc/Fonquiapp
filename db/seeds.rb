# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

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

def google_maps_url(address)
  "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(address)}"
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
    address = random_bogota_address
    zone.clients.create!(
      name: random_client_name,
      address: address,
      url: google_maps_url(address),
      phone: Faker::PhoneNumber.phone_number
    )
  end
end
clients = Client.all.to_a

# --- Default product quantities (regenerated every run) ---------------------
DefaultProductQuantity.delete_all
clients.product(products).sample(12).each do |client, product|
  DefaultProductQuantity.create!(product: product, client: client, zone: client.zone, quantity: rand(1..10))
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
