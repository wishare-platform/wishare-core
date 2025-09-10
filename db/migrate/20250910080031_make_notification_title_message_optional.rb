class MakeNotificationTitleMessageOptional < ActiveRecord::Migration[8.0]
  def change
    change_column_null :notifications, :title, true
    change_column_null :notifications, :message, true
  end
end
