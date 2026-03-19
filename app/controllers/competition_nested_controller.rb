# frozen_string_literal: true

class CompetitionNestedController < ApplicationController
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

    before_action :assign_new_resource, only: %i[new create]
  end

  protected

  def load_competition
    @competition = Competition.find_by!(year: params[:year], slug: params[:slug])
  end

  def assign_new_resource
    self.resource_instance = resource_class.new(competition: @competition)
  end

  def current_ability
    @current_ability ||= ::Ability.new(current_user, simple_access:)
  end

  def simple_access
    SimpleAccess.find_by(id: session["simple_access_#{@competition.id}"]) if session["simple_access_#{@competition.id}"]
  end
  helper_method :simple_access
end
