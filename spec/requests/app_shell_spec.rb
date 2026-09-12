require "rails_helper"

RSpec.describe "App shell", type: :request do
  describe "sidebar and header" do
    it "renders the brand label and the Zonas/Clientes links on the zone index" do
      get zones_path

      expect(response.body).to include("Fonquilac")
      links = response.parsed_body.css("a")

      expect(links.find { |a| a.text.strip == "Zonas" }["href"]).to eq(zones_path)
      expect(links.find { |a| a.text.strip == "Clientes" }["href"]).to eq(clients_path)
    end

    it "shows the page title in the header on the zone and client index" do
      get zones_path
      expect(response.parsed_body.at_css("header").text).to include("Zonas")

      get clients_path
      expect(response.parsed_body.at_css("header").text).to include("Clientes")
    end

    it "highlights Zonas but not Clientes on the zone index" do
      get zones_path
      doc = response.parsed_body

      zonas_link = doc.css("a").find { |a| a.text.strip == "Zonas" }
      clientes_link = doc.css("a").find { |a| a.text.strip == "Clientes" }

      expect(zonas_link["class"]).to include("text-accent")
      expect(clientes_link["class"]).not_to include("text-accent")
    end

    it "highlights Clientes but not Zonas on the client index" do
      get clients_path
      doc = response.parsed_body

      zonas_link = doc.css("a").find { |a| a.text.strip == "Zonas" }
      clientes_link = doc.css("a").find { |a| a.text.strip == "Clientes" }

      expect(clientes_link["class"]).to include("text-accent")
      expect(zonas_link["class"]).not_to include("text-accent")
    end

    it "lists the Productos submenu entries in order, with Productos and Default linking to their indexes" do
      get zones_path
      doc = response.parsed_body

      submenu_items = doc.css("div.hidden > a, div.hidden > span")
      expect(submenu_items.map { |el| el.text.strip }).to eq(
        ["Productos", "Default", "Pendientes", "Orden Diaria"]
      )

      productos_entry, default_entry, *rest = submenu_items

      expect(productos_entry.name).to eq("a")
      expect(productos_entry["href"]).to eq(products_path)

      expect(default_entry.name).to eq("a")
      expect(default_entry["href"]).to eq(default_product_quantities_path)

      rest.each { |el| expect(el.name).to eq("span") }
    end
  end
end
