require "rails_helper"

RSpec.describe "Header account controls", type: :request do
  it "shows the signed-in email, a password change link, and a sign-out button" do
    sign_out
    sign_in_as(create(:user, email_address: "lacteosfonquilacpc@gmail.com"))

    get clients_path

    header = response.parsed_body.at_css("header")
    expect(header.text).to include("lacteosfonquilacpc@gmail.com")
    link = header.css("a").find { |a| a.text.strip == "Cambiar contraseña" }
    expect(link["href"]).to eq(edit_password_change_path)
    sign_out_form = header.at_css("form[action='#{session_path}']")
    expect(sign_out_form.at_css("input[name='_method'][value='delete']")).not_to be_nil
    expect(sign_out_form.text).to include("Cerrar sesión")
  end
end
