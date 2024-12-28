class WishlistsController < ApplicationController
  def index
    @wishlists = current_user.wishlists
  end

  def show
    @wishlist = current_user.wishlists.find(params[:id])
  end

  def new
    @wishlist = current_user.wishlists.build
  end

  def create
    @wishlist = current_user.wishlists.build(wishlist_params)
    if @wishlist.save
      redirect_to @wishlist, notice: 'Wishlist created!'
    else
      render :new
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def wishlist_params
    params.require(:wishlist).permit(:name)
  end
end
