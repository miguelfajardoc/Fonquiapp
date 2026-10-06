require "rails_helper"

RSpec.describe "PasswordChanges", type: :request do
  let(:user) { create(:user, password: "123456") }

  before do
    sign_out
    sign_in_as(user)
  end

  def change(current:, new_password:, confirmation: new_password)
    patch password_change_path, params: { current_password: current, password: new_password,
                                          password_confirmation: confirmation }
  end

  it "renders the form inside the shell" do
    get edit_password_change_path

    body = response.parsed_body
    %w[current_password password password_confirmation].each do |name|
      expect(body.at_css("input[name='#{name}'][type='password']")).not_to be_nil
    end
    expect(body.at_css("header")).not_to be_nil
  end

  it "changes the password, keeps the user signed in, and only the new password works afterwards" do
    change(current: "123456", new_password: "nuevaClave9")

    expect(response).to redirect_to(edit_password_change_path)
    expect(flash[:notice]).to eq(I18n.t("password_changes.flash.updated"))
    get clients_path
    expect(response).to have_http_status(:ok)
    expect(user.reload.authenticate("nuevaClave9")).to be_truthy
    expect(user.authenticate("123456")).to be(false)
  end

  it "rejects a wrong current password" do
    change(current: "otra", new_password: "nuevaClave9")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(I18n.t("password_changes.errors.wrong_current"))
    expect(user.reload.authenticate("123456")).to be_truthy
  end

  it "rejects new passwords that do not match" do
    change(current: "123456", new_password: "nuevaClave9", confirmation: "otraClave9")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(I18n.t("password_changes.errors.mismatch"))
    expect(user.reload.authenticate("123456")).to be_truthy
  end

  it "rejects a blank new password" do
    change(current: "123456", new_password: "")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include(I18n.t("password_changes.errors.blank"))
  end
end
