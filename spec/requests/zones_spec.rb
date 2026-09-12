require "rails_helper"

RSpec.describe "Zones", type: :request do
  describe "GET /zones" do
    it "lists every existing zone with a create control and per-row edit/delete controls" do
      zone = create(:zone, name: "Norte")

      get zones_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(zone.name)
      expect(response.body).to include("Crear zona")
      expect(response.body).to include(edit_zone_path(zone))
      expect(response.body).to include("Eliminar")
    end

    it "renders exactly one confirmation dialog regardless of zone count" do
      create_list(:zone, 3)

      get zones_path

      expect(response.body.scan("<dialog").count).to eq(1)
      expect(response.body).to include("¿Estás seguro")
    end
  end

  describe "GET /zones/new" do
    it "renders the form with a Crear submit button" do
      get new_zone_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Crear"')
      expect(response.body).not_to include('value="Actualizar"')
    end
  end

  describe "GET /zones/:id/edit" do
    it "renders the form with an Actualizar submit button" do
      zone = create(:zone)

      get edit_zone_path(zone)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Actualizar"')
      expect(response.body).not_to include('value="Crear"')
    end
  end

  describe "POST /zones" do
    it "creates a zone with a valid name" do
      expect do
        post zones_path, params: { zone: { name: "Norte" } }
      end.to change(Zone, :count).by(1)

      expect(response).to redirect_to(zones_path)
    end

    it "re-renders the form with a blank name" do
      expect do
        post zones_path, params: { zone: { name: "" } }
      end.not_to change(Zone, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders the form with a name already taken" do
      create(:zone, name: "Norte")

      expect do
        post zones_path, params: { zone: { name: "Norte" } }
      end.not_to change(Zone, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /zones/:id" do
    it "updates a zone with a valid name" do
      zone = create(:zone, name: "Norte")

      patch zone_path(zone), params: { zone: { name: "Sur" } }

      expect(response).to redirect_to(zones_path)
      expect(zone.reload.name).to eq("Sur")
    end

    it "does not update a zone with a blank name" do
      zone = create(:zone, name: "Norte")

      patch zone_path(zone), params: { zone: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(zone.reload.name).to eq("Norte")
    end

    it "does not update a zone with a name taken by another zone" do
      create(:zone, name: "Norte")
      zone = create(:zone, name: "Sur")

      patch zone_path(zone), params: { zone: { name: "Norte" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(zone.reload.name).to eq("Sur")
    end
  end

  describe "DELETE /zones/:id" do
    it "deletes a zone with no associated records" do
      zone = create(:zone)

      expect do
        delete zone_path(zone)
      end.to change(Zone, :count).by(-1)

      expect(response).to redirect_to(zones_path)
      expect(flash[:notice]).to be_present
    end

    it "does not delete a zone still referenced by a client, and reports why" do
      zone = create(:zone)
      create(:client, zone: zone)

      expect do
        delete zone_path(zone)
      end.not_to change(Zone, :count)

      expect(response).to redirect_to(zones_path)
      expect(flash[:alert]).to be_present
      expect(Zone.exists?(zone.id)).to be(true)
    end
  end
end
