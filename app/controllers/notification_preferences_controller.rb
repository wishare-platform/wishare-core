class NotificationPreferencesController < ApplicationController
  before_action :authenticate_user!

  def show
    @notification_preference = current_user.notification_preference ||
                              current_user.build_notification_preference
  end

  def update
    @notification_preference = current_user.notification_preference ||
                              current_user.build_notification_preference

    if @notification_preference.update(notification_preference_params)
      redirect_to notification_preferences_path,
                  notice: t("notification_preferences.update.success")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def notification_preference_params
    params.require(:notification_preference).permit(
      :email_invitations,
      :email_purchases,
      :email_new_items,
      :email_connections,
      :push_enabled,
      :digest_frequency
    )
  end
end
