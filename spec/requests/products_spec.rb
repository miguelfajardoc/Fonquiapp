require "rails_helper"

RSpec.describe "Products", type: :request do
  describe "GET /products" do
    it "lists every existing product with its formatted price, a create control, and per-row edit/delete controls" do
      product = create(:product, name: "Agua 500ml", price: 12_000)

      get products_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(product.name)
      expect(response.body).to include("$12.000")
      expect(response.body).to include("Crear producto")
      expect(response.body).to include(edit_product_path(product))
      expect(response.body).to include("Eliminar")
    end

    it "renders exactly one confirmation dialog regardless of product count" do
      create_list(:product, 3)

      get products_path

      expect(response.body.scan("<dialog").count).to eq(1)
      expect(response.body).to include("¿Estás seguro")
    end
  end

  describe "GET /products with filters and pagination" do
    it "has no in-page title and puts the filter form, clear link, and create button on one row" do
      get products_path

      body = response.parsed_body
      expect(body.at_css("h1")).to be_nil
      form = body.at_css("form[method='get'][data-turbo-frame='products']")
      expect(form.at_css("input[name='name']")).not_to be_nil
      expect(form.parent.css("> a").map { |a| a.text.strip }).to include("Crear producto")
      expect(clear_filters_link["href"]).to eq(products_path)
      expect(clear_filters_link["data-turbo-frame"]).to eq("_top")
      expect(body.at_css("turbo-frame#products[data-turbo-action='advance']")).not_to be_nil
    end

    it "filters by a name fragment ignoring case and accents, and pre-fills the box" do
      create(:product, name: "Queso Añejo")
      create(:product, name: "Crema de leche")

      get products_path(name: "ANEJO")

      expect(frame_column("products", 0)).to eq(["Queso Añejo"])
      expect(response.parsed_body.at_css("input[name='name']")["value"]).to eq("ANEJO")
    end

    it "shows a message when no product matches" do
      create(:product, name: "Queso")

      get products_path(name: "zzz")

      expect(frame_rows("products")).to be_empty
      expect(response.body).to include(I18n.t("products.index.no_results"))
    end

    context "with more products than fit on one page" do
      before do
        25.times { |n| create(:product, name: format("Queso %02d", n)) }
        5.times { |n| create(:product, name: format("Crema %02d", n)) }
      end

      it "paginates 20 per page in name order, keeping the filter on page links" do
        get products_path(name: "queso")

        expect(frame_column("products", 0).first).to eq("Queso 00")
        expect(frame_rows("products").size).to eq(20)
        expect(next_page_query("products")).to include("name" => "queso", "page" => "2")

        get products_path(name: "queso", page: 2)

        expect(frame_column("products", 0)).to eq((20..24).map { |n| format("Queso %02d", n) })
      end
    end

    it "shows no pagination controls when every product fits on one page" do
      create_list(:product, 3)

      get products_path

      expect(frame_rows("products").size).to eq(3)
      expect(pagination_nav("products")).to be_nil
    end
  end

  describe "GET /products/new" do
    it "renders the form with a Crear submit button" do
      get new_product_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Crear"')
      expect(response.body).not_to include('value="Actualizar"')
    end
  end

  describe "GET /products/:id/edit" do
    it "renders the form with an Actualizar submit button" do
      product = create(:product)

      get edit_product_path(product)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Actualizar"')
      expect(response.body).not_to include('value="Crear"')
    end
  end

  describe "POST /products" do
    it "creates a product with a valid name and price" do
      expect do
        post products_path, params: { product: { name: "Agua 500ml", price: 1500 } }
      end.to change(Product, :count).by(1)

      expect(response).to redirect_to(products_path)
    end

    it "re-renders the form with a blank name" do
      expect do
        post products_path, params: { product: { name: "", price: 1500 } }
      end.not_to change(Product, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders the form with a name already taken" do
      create(:product, name: "Agua 500ml")

      expect do
        post products_path, params: { product: { name: "Agua 500ml", price: 1500 } }
      end.not_to change(Product, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders the form with a negative price" do
      expect do
        post products_path, params: { product: { name: "Agua 500ml", price: -1 } }
      end.not_to change(Product, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /products/:id" do
    it "updates a product with a valid name and price" do
      product = create(:product, name: "Agua 500ml", price: 1500)

      patch product_path(product), params: { product: { name: "Agua 600ml", price: 1800 } }

      expect(response).to redirect_to(products_path)
      product.reload
      expect(product.name).to eq("Agua 600ml")
      expect(product.price).to eq(1800)
    end

    it "does not update a product with a negative price" do
      product = create(:product, price: 1500)

      patch product_path(product), params: { product: { price: -1 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(product.reload.price).to eq(1500)
    end
  end

  describe "DELETE /products/:id" do
    it "deletes a product with no associated records" do
      product = create(:product)

      expect do
        delete product_path(product)
      end.to change(Product, :count).by(-1)

      expect(response).to redirect_to(products_path)
      expect(flash[:notice]).to be_present
    end

    it "does not delete a product still referenced by a pending product, and reports why" do
      product = create(:product)
      create(:pending_product, product: product)

      expect do
        delete product_path(product)
      end.not_to change(Product, :count)

      expect(response).to redirect_to(products_path)
      expect(flash[:alert]).to be_present
      expect(Product.exists?(product.id)).to be(true)
    end
  end
end
