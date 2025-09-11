# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    # Check if user has a password set (OAuth-only users might not)
    has_password = resource.encrypted_password.present?
    
    # If user has no password (OAuth only) and isn't setting one, update without password
    if !has_password && params[resource_name][:password].blank?
      resource_updated = update_resource_without_password(resource, account_update_params)
    else
      resource_updated = update_resource(resource, account_update_params)
    end

    yield resource if block_given?
    if resource_updated
      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  private

  def update_resource_without_password(resource, params)
    # Remove password fields if blank
    params.delete(:password)
    params.delete(:password_confirmation)
    params.delete(:current_password)
    
    resource.update(params)
  end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :date_of_birth, :preferred_locale])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :avatar_url, :date_of_birth, :preferred_locale])
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    # If user signed up through an invitation link, check for pending invitations
    invitation = Invitation.find_by(recipient_email: resource.email, status: 'pending')
    if invitation
      accept_invitation_path(invitation.token)
    else
      super(resource)
    end
  end
end
