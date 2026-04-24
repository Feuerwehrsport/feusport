# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include AccessDeniedSupport
  include ExportsSupport
  include ActiveStorage::SetCurrent
  include TabSessionIdSupport

  before_action :ensure_correct_host!

  protected

  def default_url_options
    Rails.application.config.default_url_options
  end

  private

  def ensure_correct_host!
    expected =    Rails.application.config.default_url_options

    return if expected.blank?

    correct_host     = expected[:host].to_s
    correct_port     = expected[:port].to_s
    correct_protocol = expected[:protocol].to_s

    current_host     = request.host.to_s
    current_port     = request.port.to_s
    current_protocol = request.protocol.delete("://").to_s

    needs_redirect =
      (correct_host.present? && current_host != correct_host) ||
      (correct_port.present? && current_port != correct_port) ||
      (correct_protocol.present? && current_protocol != correct_protocol)

    if needs_redirect
      redirect_to url_for(
        params.permit!.to_h.merge(
          host: correct_host,
          port: correct_port,
          protocol: correct_protocol
        )
      ), status: :moved_permanently
    end
  end
end
