class ItemPurchaseMailer < ApplicationMailer
  def item_purchased(notification)
    @notification = notification
    @user = @notification.user
    @purchaser_name = @notification.data['purchaser_name']
    @item_name = @notification.data['item_name']
    @wishlist_name = @notification.data['wishlist_name']
    @wishlist_id = @notification.data['wishlist_id']
    @wishlist_url = wishlist_url(@wishlist_id)
    
    I18n.with_locale(@user.preferred_locale || I18n.default_locale) do
      mail(
        to: @user.email,
        subject: t('emails.item_purchase.subject', item_name: @item_name)
      )
    end
  end
end