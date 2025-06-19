# app/channels/notification_channel.rb
class NotificationChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
    stream_from "notifications_#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end

  def self.broadcast_to(user, message)
    ActionCable.server.broadcast("notifications_#{user.id}", message)
  end
end

# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :recipient, class_name: 'User'
  belongs_to :actor, class_name: 'User', optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  after_commit :broadcast_notification, on: :create

  private

  def broadcast_notification
    NotificationChannel.broadcast_to(
      recipient,
      ApplicationController.render(
        partial: 'notifications/notification',
        locals: { notification: self }
      )
    )
  end
end
