require "rails_helper"

RSpec.describe "Authentication", :signed_out, type: :request do
  let!(:user) { create(:user, email_address: "lacteosfonquilacpc@gmail.com", password: "123456") }

  def log_in(email: user.email_address, password: "123456")
    post session_path, params: { email_address: email, password: password }
  end

  describe "access control" do
    it "redirects a signed-out visitor to the login page without showing data" do
      create(:client, name: "Tienda Secreta")

      get clients_path

      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect(response.body).not_to include("Tienda Secreta")
    end

    it "returns to the originally requested page after signing in" do
      get products_path(name: "queso")
      log_in

      expect(response).to redirect_to(products_url(name: "queso"))
    end

    it "goes to the root page when there was no requested page" do
      log_in

      expect(response).to redirect_to(root_url)
    end

    it "keeps the health check public" do
      get rails_health_check_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "login page" do
    it "renders in Spanish, styled, without the application shell" do
      get new_session_path

      body = response.parsed_body
      expect(body.at_css("h1").text).to include("Iniciar sesión")
      expect(body.at_css("input[name='email_address']")).not_to be_nil
      expect(body.at_css("input[name='password'][type='password']")).not_to be_nil
      expect(body.at_css("input[type=submit]")["value"]).to eq("Ingresar")
      expect(body.at_css("aside, header")).to be_nil
      expect(response.body).not_to include("Forgot", "Olvidé")
    end
  end

  describe "POST /session" do
    it "signs in with valid credentials" do
      log_in
      get clients_path

      expect(response).to have_http_status(:ok)
    end

    it "ignores email case and surrounding spaces" do
      log_in(email: " LacteosFonquilacPC@gmail.com ")
      get clients_path

      expect(response).to have_http_status(:ok)
    end

    it "shows the same generic error for a wrong password and an unknown email" do
      log_in(password: "mala")
      wrong_password_alert = flash[:alert]
      log_in(email: "nadie@example.com")

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(wrong_password_alert)
      expect(flash[:alert]).to eq(I18n.t("sessions.flash.invalid_credentials"))
      get clients_path
      expect(response).to redirect_to(new_session_path)
    end

    it "rate-limits repeated attempts" do
      allow(Rails.cache).to receive(:increment).and_return(11)

      log_in

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq(I18n.t("sessions.flash.rate_limited"))
    end

    it "records the session with IP address and user agent" do
      post session_path, params: { email_address: user.email_address, password: "123456" },
                         headers: { "User-Agent" => "RSpec Browser" }

      session = user.sessions.last
      expect(session.user_agent).to eq("RSpec Browser")
      expect(session.ip_address).to be_present
    end
  end

  describe "DELETE /session" do
    it "signs out and requires login again" do
      log_in

      delete session_path

      expect(response).to redirect_to(new_session_path)
      get clients_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "routes that must not exist" do
    it "offers no sign-up or password reset" do
      %w[/passwords/new /registrations/new /users/new /sign_up].each do |path|
        expect { Rails.application.routes.recognize_path(path) }.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
