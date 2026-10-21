# frozen_string_literal: true

class CompetitionNestedController < ApplicationController
  SIMPLE_ACCESS_TIMEOUT = 1.hour

  before_action :load_competition
  authorize_resource :competition

  def self.default_resource(resource_class: nil, name: nil, through_association: nil)
    namespace = controller_path.split('/')[0..-2]
    name ||= controller_path.split('/').last.singularize
    load_and_authorize_resource(name.to_sym, through: :competition, class: resource_class, through_association:)
    namespaced_name = [namespace, name].join('/').singularize.camelize.safe_constantize || name

    define_method(:resource_class) do
      @resource_class ||= resource_class || namespaced_name.to_s.camelize.constantize
    end
    helper_method :resource_class

    define_method(:resource_instance) do
      instance_variable_get(:"@#{name}")
    end
    helper_method :resource_instance

    define_method(:resource_instance=) do |new_value|
      instance_variable_set(:"@#{name}", new_value)
    end

    define_method(:resource_collection) do
      instance_variable_get(:"@#{name.to_s.pluralize}")
    end
    helper_method :resource_collection

    define_method(:pdf_support?) do
      true
    end
    helper_method :pdf_support?

    define_method(:xlsx_support?) do
      true
    end
    helper_method :xlsx_support?

    before_action :assign_new_resource, if: -> { action_name.in?(%w[new create]) }
  end

  protected

  def load_competition
    @competition = Competition.find_by!(year: params[:year], slug: params[:slug])
  end

  def assign_new_resource
    self.resource_instance = resource_class.new(competition: @competition)
  end

  def current_ability
    @current_ability ||= ::Ability.new(current_user, simple_access: current_simple_access)
  end

  # Admins (inkl. Gastzugang) sehen Ergebnisse inklusive nicht öffentlicher Startlisten (Score::List#results_public?)
  def include_hidden_lists?
    can?(:manage, @competition)
  end
  helper_method :include_hidden_lists?

  def current_simple_access
    return @current_simple_access if defined?(@current_simple_access)

    @current_simple_access = load_simple_access_from_session
  end
  helper_method :current_simple_access

  def remember_simple_access(simple_access)
    session[simple_access_session_key] = { 'id' => simple_access.id, 'last_seen_at' => Time.current.to_i }
  end

  def forget_simple_access
    session.delete(simple_access_session_key)
  end

  # Gast-Sessions laufen nach einer Stunde ohne Anfrage ab, jede Anfrage verlängert sie.
  def load_simple_access_from_session
    data = forget_simple_access
    return unless data.is_a?(Hash) && Time.zone.at(data['last_seen_at'].to_i) > SIMPLE_ACCESS_TIMEOUT.ago

    SimpleAccess.find_by(id: data['id'])&.tap { |simple_access| remember_simple_access(simple_access) }
  end

  def simple_access_session_key
    "simple_access_#{@competition.id}"
  end
end
