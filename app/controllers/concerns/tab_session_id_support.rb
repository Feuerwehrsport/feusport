# frozen_string_literal: true

module TabSessionIdSupport
  extend ActiveSupport::Concern

  class Current < ActiveSupport::CurrentAttributes
    attribute :tab_session_id
  end

  included do
    before_action { Current.tab_session_id = params[:tab_session_id] }
  end
end
