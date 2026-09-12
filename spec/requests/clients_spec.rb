require "rails_helper"

RSpec.describe "Clients", type: :request do
  describe "GET /clients" do
    it "lists every existing client with its fields, a create control, and a delete control" do
      zone = create(:zone, name: "Norte")
      client = create(:client, name: "Acme", address: "Calle 1", url: "https://acme.test",
                               phone: "555-0100", zone: zone)

      get clients_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(client.name)
      expect(response.body).to include(client.address)
      expect(response.body).to include(client.url)
      expect(response.body).to include(client.phone)
      expect(response.body).to include(zone.name)
      expect(response.body).to include("Crear cliente")
      expect(response.body).to include(client_path(client))
      expect(response.body).to include("Eliminar")
    end
  end

  describe "GET /clients/:id" do
    it "shows every field and an edit and delete control" do
      zone = create(:zone, name: "Norte")
      client = create(:client, name: "Acme", address: "Calle 1", url: "https://acme.test",
                               phone: "555-0100", zone: zone)

      get client_path(client)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(client.name)
      expect(response.body).to include(client.address)
      expect(response.body).to include(client.url)
      expect(response.body).to include(client.phone)
      expect(response.body).to include(zone.name)
      expect(response.body).to include(edit_client_path(client))
      expect(response.body).to include("Eliminar")
    end
  end

  describe "GET /clients/new" do
    it "renders the form with a Crear submit button" do
      get new_client_path

      expect(response).to have_http_status(:ok)
      client_form = response.parsed_body.at_css("form[action='#{clients_path}']")
      expect(client_form.at_css("input[type=submit]")["value"]).to eq("Crear")
    end

    it "offers creating a zone as an option inside the zone select itself" do
      zone = create(:zone, name: "Norte")

      get new_client_path

      zone_select = response.parsed_body.at_css("#client_zone_select")
      expect(zone_select.at_css("option[value='#{zone.id}']").text).to eq("Norte")
      expect(zone_select.at_css("option[value='new']").text).to eq("+ Crear zona")
    end
  end

  describe "GET /clients/:id/edit" do
    it "renders the form with an Actualizar submit button" do
      client = create(:client)

      get edit_client_path(client)

      expect(response).to have_http_status(:ok)
      client_form = response.parsed_body.at_css("form[action='#{client_path(client)}']")
      expect(client_form.at_css("input[type=submit]")["value"]).to eq("Actualizar")
    end
  end

  describe "POST /clients" do
    it "creates a client with a name and a zone" do
      zone = create(:zone)

      expect do
        post clients_path, params: { client: { name: "Acme", zone_id: zone.id } }
      end.to change(Client, :count).by(1)

      expect(response).to redirect_to(clients_path)
    end

    it "re-renders the form with a blank name" do
      zone = create(:zone)

      expect do
        post clients_path, params: { client: { name: "", zone_id: zone.id } }
      end.not_to change(Client, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders the form with no zone selected" do
      expect do
        post clients_path, params: { client: { name: "Acme", zone_id: "" } }
      end.not_to change(Client, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /clients/:id" do
    it "updates a client with valid data" do
      client = create(:client, name: "Acme")
      zone = create(:zone)

      patch client_path(client), params: { client: { name: "Acme Corp", zone_id: zone.id } }

      expect(response).to redirect_to(clients_path)
      expect(client.reload.name).to eq("Acme Corp")
    end

    it "does not update a client with a blank name" do
      client = create(:client, name: "Acme")

      patch client_path(client), params: { client: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(client.reload.name).to eq("Acme")
    end

    it "does not update a client with no zone selected" do
      client = create(:client, name: "Acme")

      patch client_path(client), params: { client: { zone_id: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /clients/:id" do
    it "deletes a client with no associated records" do
      client = create(:client)

      expect do
        delete client_path(client)
      end.to change(Client, :count).by(-1)

      expect(response).to redirect_to(clients_path)
      expect(flash[:notice]).to be_present
    end

    it "does not delete a client still referenced by an ordering record, and reports why" do
      client = create(:client)
      create(:daily_product_order, client: client)

      expect do
        delete client_path(client)
      end.not_to change(Client, :count)

      expect(response).to redirect_to(clients_path)
      expect(flash[:alert]).to be_present
      expect(Client.exists?(client.id)).to be(true)
    end
  end
end
