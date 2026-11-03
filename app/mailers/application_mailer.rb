# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  class DeliveryJob < ActionMailer::MailDeliveryJob
    retry_on Net::SMTPError, Timeout::Error, OpenSSL::OpenSSLError, SystemCallError, IOError, SocketError,
             wait: :polynomially_longer, attempts: 10
  end

  self.delivery_job = DeliveryJob

  # Jobs bringen die Sprache mit, mit der sie eingeplant wurden. Mails sind immer deutsch.
  around_action { |_mailer, action| I18n.with_locale(:de, &action) }

  def mail(*)
    attachments.inline['logo.png'] = {
      mime_type: 'image/png',
      content: Rails.root.join('app/assets/images/logo.png').read,
    }
    super
  end

  protected

  def default_url_options
    Rails.application.config.default_url_options
  end
end
