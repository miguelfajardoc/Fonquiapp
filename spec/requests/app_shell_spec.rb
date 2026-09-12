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

    it "lists the Productos submenu entries in order with no links or buttons" do
      get zones_path
      doc = response.parsed_body

      expect(doc.css("a").map { |a| a.text.strip }).not_to include("Productos")
      expect(doc.css("button").map { |b| b.text.strip }).not_to include("Productos")

      submenu_names = ["Productos", "Default", "Pendientes", "Orden Diaria"]
      submenu_labels = doc.css("span").map { |span| span.text.strip }.select do |text|
        submenu_names.include?(text)
      end

      expect(submenu_labels).to eq(submenu_names)
    end
  end
end
