# frozen_string_literal: true

class Admin::DisseminatorsController < Admin::ResourcesController
  protected

  def resource_class = Disseminator
  def resource_order = :name
  def permitted_attributes = %i[name lfv position email_address phone_number]
end
