class ProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to profile_path, notice: t('profile.update_success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_avatar
    @user = current_user

    if params[:avatar].present?
      @user.avatar.attach(params[:avatar])
      if @user.save
        render json: { success: true, avatar_url: @user.profile_avatar_url }
      else
        render json: { success: false, errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: 'No image provided' }, status: :unprocessable_entity
    end
  end

  def remove_avatar
    @user = current_user

    if @user.avatar.attached?
      @user.avatar.purge
      render json: { success: true }
    else
      render json: { success: false, error: 'No avatar to remove' }, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email, :date_of_birth, :street_address, :street_number,
                                 :apartment_unit, :city, :state, :postal_code, :country,
                                 :address_visibility, :preferred_locale, :theme_preference, :avatar,
                                 :bio, :website, :gender, :instagram_username, :tiktok_username,
                                 :twitter_username, :linkedin_url, :youtube_url, :facebook_url,
                                 :bio_visibility, :social_links_visibility, :website_visibility)
  end
end