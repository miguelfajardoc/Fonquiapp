class PasswordChangesController < ApplicationController
  def edit; end

  def update
    @error = password_change_error
    if @error.nil? && Current.user.update(password: new_password, password_confirmation: new_password_confirmation)
      redirect_to edit_password_change_path, notice: t("password_changes.flash.updated")
    else
      @error ||= Current.user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_content
    end
  end

  private

  def password_change_error
    return t("password_changes.errors.wrong_current") unless Current.user.authenticate(params[:current_password].to_s)
    return t("password_changes.errors.blank") if new_password.blank?

    t("password_changes.errors.mismatch") unless new_password == new_password_confirmation
  end

  def new_password = params[:password].to_s
  def new_password_confirmation = params[:password_confirmation].to_s
end
