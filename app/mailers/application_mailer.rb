# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  class DeliveryJob < ActionMailer::MailDeliveryJob
    retry_on Net::SMTPError, Timeout::Error, OpenSSL::OpenSSLError, SystemCallError, IOError, SocketError,
             wait: :exponentially_longer, attempts: 10
  end

  self.delivery_job = DeliveryJob

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
