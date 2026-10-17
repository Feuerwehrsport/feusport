# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

HCAPTCHA_SOURCES = %w[https://hcaptcha.com https://*.hcaptcha.com].freeze

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.form_action :self
    policy.object_src  :none
    # Nicht in fremde Seiten einbettbar, nur die eigene Urkunden-Vorschau (iframe) braucht 'self'
    policy.frame_ancestors :self
    policy.font_src    :self, :data
    # Bilder: eigene Uploads, QR-Code als data:-URL, OSM-Kacheln (Leaflet)
    policy.img_src     :self, :data, :blob, :https
    # Keine Inline-Skripte und keine Event-Handler-Attribute, nur gebündeltes JS und hCaptcha
    policy.script_src  :self, *HCAPTCHA_SOURCES
    # style-Attribute in Views und im per innerHTML eingefügten HTML sowie Turbo/Leaflet brauchen 'unsafe-inline'
    policy.style_src   :self, :unsafe_inline, *HCAPTCHA_SOURCES
    policy.frame_src   :self, *HCAPTCHA_SOURCES
    # Adresssuche über Nominatim, ActionCable läuft über :self
    policy.connect_src :self, 'https://nominatim.openstreetmap.org', *HCAPTCHA_SOURCES
  end

  # Bewusst ohne Nonce: Es gibt keine Inline-Skripte. Ein Nonce bei style-src würde 'unsafe-inline' außer Kraft setzen.
end
