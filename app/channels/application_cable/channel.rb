# frozen_string_literal: true

class ApplicationCable::Channel < ActionCable::Channel::Base
  private

  def ability_for(competition)
    ::Ability.new(current_user, simple_access: SimpleAccess.from_session(connection.session, competition))
  end
end
