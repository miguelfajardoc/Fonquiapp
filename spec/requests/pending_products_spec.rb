require "rails_helper"

RSpec.describe "PendingProducts", type: :request do
  describe "GET /pending_products" do
    it "lists every record's date, client, product, quantity, and state, with edit/delete/toggle controls" do
      client = create(:client, name: "Tienda Norte")
      product = create(:product, name: "Agua 500ml")
      record = create(:pending_product, client: client, zone: client.zone, product: product, quantity: 4)

      get pending_products_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(client.name)
      expect(response.body).to include(product.name)
      expect(response.body).to include("4")
      expect(response.body).to include("Pendiente")
      expect(response.body).to include("Crear Pendiente")
      expect(response.body).to include(edit_pending_product_path(record, context: "table"))
      expect(response.body).to include(toggle_state_pending_product_path(record, context: "table"))
      expect(response.body).to include("Eliminar")
    end

    it "renders exactly one confirmation dialog and one edit modal regardless of record count" do
      create_list(:pending_product, 3)

      get pending_products_path

      expect(response.body.scan("<dialog").count).to eq(2)
    end

    it "does not render a toggle control for a canceled record" do
      record = create(:pending_product, state: :canceled)

      get pending_products_path(state: "all")

      expect(response.body).to include(record.client.name)

      expect(response.body).not_to include(toggle_state_pending_product_path(record, context: "table"))
    end
  end

  describe "GET /pending_products with filters, sort, and pagination" do
    let(:zone) { create(:zone, name: "Bosa") }
    let(:other_zone) { create(:zone, name: "Soacha") }

    def pending_for(client_name, in_zone, **attrs)
      create(:pending_product, zone: in_zone, client: create(:client, name: client_name, zone: in_zone), **attrs)
    end

    it "has no in-page title and puts every filter, the clear link, and the create button on one row" do
      get pending_products_path

      body = response.parsed_body
      expect(body.at_css("h1")).to be_nil
      form = body.at_css("form[method='get'][data-turbo-frame='pending_products']")
      %w[zone_id state sort].each { |name| expect(form.at_css("select[name='#{name}']")).not_to be_nil }
      expect(form.at_css("input[name='client_name']")).not_to be_nil
      expect(form.css("select[name='state'] option").map { |o| o.text.strip })
        .to eq(["Todos los estados", "Pendiente", "Entregado", "Cancelado"])
      expect(form.at_css("select[name='state'] option[value='all']").text.strip).to eq("Todos los estados")
      expect(form.parent.css("> a").map { |a| a.text.strip }).to include("Crear Pendiente")
      expect(clear_filters_link["href"]).to eq(pending_products_path)
      expect(body.at_css("dialog")).not_to be_nil
    end

    it "shows a Zona column after Cliente" do
      pending_for("Tienda Norte", zone)

      get pending_products_path

      headers = frame_headers("pending_products")
      expect(headers[headers.index("Cliente") + 1]).to eq("Zona")
      expect(frame_column("pending_products", 2)).to eq(["Bosa"])
    end

    it "filters by zone, client name (ignoring accents), and state, also combined" do
      pending_for("Tienda San José", zone, state: :pending)
      pending_for("Salsamentaria", zone, state: :delivered)
      pending_for("Tienda Centro", other_zone, state: :pending)

      get pending_products_path(client_name: "JOSE")
      expect(frame_column("pending_products", 1)).to eq(["Tienda San José"])

      get pending_products_path(zone_id: zone.id, state: "all")
      expect(frame_column("pending_products", 1)).to contain_exactly("Tienda San José", "Salsamentaria")

      get pending_products_path(state: "delivered")
      expect(frame_column("pending_products", 1)).to eq(["Salsamentaria"])

      get pending_products_path(zone_id: zone.id, state: "pending")
      expect(frame_column("pending_products", 1)).to eq(["Tienda San José"])
      expect(response.parsed_body.at_css("select[name='state'] option[selected]")["value"]).to eq("pending")
    end

    it "defaults the state filter to Pendiente, and state=all lists every state" do
      pending_for("Por Entregar", zone, state: :pending)
      pending_for("Ya Entregado", zone, state: :delivered)
      pending_for("Cancelado", zone, state: :canceled)

      get pending_products_path
      expect(frame_column("pending_products", 1)).to eq(["Por Entregar"])
      expect(response.parsed_body.at_css("select[name='state'] option[selected]")["value"]).to eq("pending")

      get pending_products_path(state: "all")
      expect(frame_column("pending_products", 1)).to contain_exactly("Por Entregar", "Ya Entregado", "Cancelado")
      expect(response.parsed_body.at_css("select[name='state'] option[selected]")["value"]).to eq("all")
    end

    it "lists the most recent first by default and the oldest first with sort=oldest" do
      pending_for("Ayer", zone, created_at: 1.day.ago)
      pending_for("Hoy", zone, created_at: Time.current)

      get pending_products_path
      expect(frame_column("pending_products", 1)).to eq(%w[Hoy Ayer])

      get pending_products_path(sort: "oldest")
      expect(frame_column("pending_products", 1)).to eq(%w[Ayer Hoy])
      expect(response.parsed_body.at_css("select[name='sort'] option[selected]")["value"]).to eq("oldest")
    end

    it "shows a message when no record matches" do
      pending_for("Tienda", zone)

      get pending_products_path(client_name: "zzz")

      expect(frame_rows("pending_products")).to be_empty
      expect(response.body).to include(I18n.t("pending_products.index.no_results"))
    end

    it "paginates 20 per page, keeping the state filter and sort on page links" do
      25.times { |n| pending_for(format("Pend %02d", n), zone, state: :pending, created_at: n.minutes.ago) }
      5.times { |n| pending_for("Entregado #{n}", zone, state: :delivered) }

      get pending_products_path(state: "pending", sort: "oldest")

      expect(frame_rows("pending_products").size).to eq(20)
      expect(next_page_query("pending_products")).to include("state" => "pending", "sort" => "oldest", "page" => "2")

      get pending_products_path(state: "pending", sort: "oldest", page: 2)

      expect(frame_column("pending_products", 1)).to eq((0..4).to_a.reverse.map { |n| format("Pend %02d", n) })
    end

    it "shows no pagination controls when every record fits on one page" do
      3.times { |n| pending_for("Cliente #{n}", zone) }

      get pending_products_path

      expect(frame_rows("pending_products").size).to eq(3)
      expect(pagination_nav("pending_products")).to be_nil
    end
  end

  describe "GET /pending_products/new" do
    it "renders the creation form with a Crear submit button" do
      get new_pending_product_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Crear"')
    end

    it "shows a choose-a-client message when no client is selected" do
      get new_pending_product_path

      expect(response.body).to include("Selecciona un cliente")
    end

    it "shows the chosen client's pending products when client_id is given" do
      client = create(:client, name: "Tienda Sur")
      other_client = create(:client, name: "Tienda Norte")
      product = create(:product, name: "Gaseosa 1L")
      matching = create(:pending_product, client: client, zone: client.zone, product: product, quantity: 2)
      create(:pending_product, client: other_client, zone: other_client.zone)

      get new_pending_product_path(client_id: client.id)

      expect(response.body).to include("Pendientes Cliente #{client.name}")
      expect(response.body).to include(product.name)
      expect(response.body).to include(dom_id_for(matching))
    end
  end

  describe "GET /pending_products/client_options" do
    it "returns matching clients across all zones" do
      zone_a = create(:zone)
      zone_b = create(:zone)
      client_in_a = create(:client, zone: zone_a, name: "Tienda A")
      client_in_b = create(:client, zone: zone_b, name: "Tienda B")

      get client_options_pending_products_path, as: :turbo_stream

      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(client_in_a.name)
      expect(response.body).to include(client_in_b.name)
    end

    it "narrows by the search query" do
      matching = create(:client, name: "Tienda Norte")
      other = create(:client, name: "Tienda Sur")

      get client_options_pending_products_path(q: "Norte"), as: :turbo_stream

      expect(response.body).to include(matching.name)
      expect(response.body).not_to include(other.name)
    end
  end

  describe "POST /pending_products" do
    it "creates a pending record for the client's zone, updating the client panel and form via turbo_stream" do
      client = create(:client)
      product = create(:product)

      expect do
        post pending_products_path, params: {
          pending_product: { client_id: client.id, product_id: product.id, quantity: 3 }
        }, as: :turbo_stream
      end.to change(PendingProduct, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)

      record = PendingProduct.last
      expect(record.state).to eq("pending")
      expect(record.zone_id).to eq(client.zone_id)
      expect(response.body).to include("turbo-stream")
      expect(response.body).to include(dom_id_for(client, :pending_products))
      expect(response.body).to include("pending_product_form")
    end

    it "does not create a record with an invalid quantity, re-rendering the form with an error" do
      client = create(:client)
      product = create(:product)

      expect do
        post pending_products_path, params: {
          pending_product: { client_id: client.id, product_id: product.id, quantity: 0 }
        }, as: :turbo_stream
      end.not_to change(PendingProduct, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("pending_product_form")
    end
  end

  describe "GET /pending_products/:id/edit" do
    it "renders the edit form inside the modal's turbo frame with an Actualizar button" do
      record = create(:pending_product)

      get edit_pending_product_path(record, context: "table")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Actualizar"')
      expect(response.body).to include("pending_product_edit_modal")
    end
  end

  describe "PATCH /pending_products/:id" do
    it "updates the record and replaces its row via turbo_stream, for both the table and panel contexts" do
      record = create(:pending_product, quantity: 2)

      patch pending_product_path(record, context: "table"), params: {
        pending_product: { quantity: 9 }
      }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(dom_id_for(record))
      expect(record.reload.quantity).to eq(9)
    end

    it "does not update with an invalid quantity, re-rendering the edit frame with a validation error" do
      record = create(:pending_product, quantity: 5)

      patch pending_product_path(record, context: "panel"), params: {
        pending_product: { quantity: -1 }
      }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("pending_product_edit_modal")
      expect(record.reload.quantity).to eq(5)
    end
  end

  describe "PATCH /pending_products/:id/toggle_state" do
    it "toggles a pending record to delivered" do
      record = create(:pending_product, state: :pending)

      patch toggle_state_pending_product_path(record, context: "table"), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dom_id_for(record))
      expect(record.reload.state).to eq("delivered")
    end

    it "toggles a delivered record back to pending" do
      record = create(:pending_product, state: :delivered)

      patch toggle_state_pending_product_path(record, context: "table"), as: :turbo_stream

      expect(record.reload.state).to eq("pending")
    end
  end

  describe "DELETE /pending_products/:id" do
    it "removes the record via turbo_stream" do
      record = create(:pending_product)

      expect do
        delete pending_product_path(record), as: :turbo_stream
      end.to change(PendingProduct, :count).by(-1)

      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(dom_id_for(record))
    end

    it "redirects to the index with a notice for a plain html request" do
      record = create(:pending_product)

      delete pending_product_path(record)

      expect(response).to redirect_to(pending_products_path)
      expect(flash[:notice]).to be_present
    end
  end

  def dom_id_for(record, prefix = nil)
    ActionView::RecordIdentifier.dom_id(record, prefix)
  end
end
