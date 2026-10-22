require "rails_helper"

RSpec.describe "App shell", type: :request do
  # Top-level sidebar entries in order: links directly under the nav, plus the Rutas group header.
  def top_level_entries
    response.parsed_body.at_css("aside nav").element_children.map do |element|
      element.name == "a" ? element : element.element_children.first
    end
  end

  def entry(label)
    top_level_entries.find { |element| element.text.strip == label }
  end

  def highlighted_entries
    top_level_entries.select { |element| element["class"].include?("text-accent") }.map { |e| e.text.strip }
  end

  describe "sidebar and header" do
    it "renders the brand label and the top-level entries in order" do
      get zones_path

      expect(response.body).to include("Fonquilac")
      expect(top_level_entries.map { |element| element.text.strip })
        .to eq(["Zonas", "Clientes", "Rutas", "Productos", "Pendientes", "Orden Diaria"])
    end

    it "links Zonas, Clientes, Productos, Pendientes and Orden Diaria to their indexes" do
      get zones_path

      expect(entry("Zonas")["href"]).to eq(zones_path)
      expect(entry("Clientes")["href"]).to eq(clients_path)
      expect(entry("Productos")["href"]).to eq(products_path)
      expect(entry("Pendientes")["href"]).to eq(pending_products_path)
      expect(entry("Orden Diaria")["href"]).to eq(daily_product_orders_path)
    end

    it "makes Rutas a non-link group whose hover submenu lists Rutas and Default" do
      get zones_path

      expect(entry("Rutas").name).not_to eq("a")
      submenu = response.parsed_body.css("aside nav div.hidden.group-hover\\:flex")
      expect(submenu.size).to eq(1)
      links = submenu.first.css("a")
      expect(links.map { |a| a.text.strip }).to eq(%w[Rutas Default])
      expect(links.pluck("href")).to eq([routes_path, default_product_quantities_path])
    end

    it "shows the page title in the header on the zone and client index" do
      get zones_path
      expect(response.parsed_body.at_css("header").text).to include("Zonas")

      get clients_path
      expect(response.parsed_body.at_css("header").text).to include("Clientes")
    end

    {
      "zones" => "Zonas", "clients" => "Clientes", "routes" => "Rutas", "default_product_quantities" => "Rutas",
      "products" => "Productos", "pending_products" => "Pendientes", "daily_product_orders" => "Orden Diaria"
    }.each do |section, label|
      it "highlights only #{label} on the #{section} index" do
        get public_send("#{section}_path")

        expect(highlighted_entries).to eq([label])
      end
    end
  end
end
