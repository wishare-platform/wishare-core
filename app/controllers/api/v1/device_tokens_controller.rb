class Api::V1::DeviceTokensController < ApplicationController
  before_action :authenticate_user!
  before_action :set_device_token, only: [:show, :destroy]

  # POST /api/v1/device_tokens
  def create
    @device_token = DeviceToken.register_token(
      user: current_user,
      token: device_token_params[:token],
      platform: device_token_params[:platform]
    )

    if @device_token.persisted?
      render json: {
        status: 'success',
        message: 'Device token registered successfully',
        device_token: {
          id: @device_token.id,
          platform: @device_token.platform,
          active: @device_token.active,
          created_at: @device_token.created_at
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: 'Failed to register device token',
        errors: @device_token.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/device_tokens
  def index
    @device_tokens = current_user.device_tokens.active.order(last_used_at: :desc)

    render json: {
      status: 'success',
      device_tokens: @device_tokens.map do |token|
        {
          id: token.id,
          platform: token.platform,
          active: token.active,
          last_used_at: token.last_used_at,
          created_at: token.created_at
        }
      end
    }
  end

  # DELETE /api/v1/device_tokens/:id
  def destroy
    @device_token.deactivate!

    render json: {
      status: 'success',
      message: 'Device token deactivated successfully'
    }
  end

  private

  def set_device_token
    @device_token = current_user.device_tokens.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Device token not found'
    }, status: :not_found
  end

  def device_token_params
    params.require(:device_token).permit(:token, :platform)
  end
end