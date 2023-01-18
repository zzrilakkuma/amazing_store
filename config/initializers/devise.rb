# frozen_string_literal: true

Devise.secret_key = SecureRandom.hex(50).inspect
Devise.setup do |config|
  config.parent_controller = 'StoreDeviseController'
  config.mailer = 'UserMailer'
  # Required so users don't lose their carts when they need to confirm.
  config.allow_unconfirmed_access_for = 1.days
end
