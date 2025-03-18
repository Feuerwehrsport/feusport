# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include AccessDeniedSupport
  include ExportsSupport
  include ActiveStorage::SetCurrent
  include TabSessionIdSupport

  protected

  def default_url_options
    Rails.application.config.default_url_options
  end
end
