# frozen_string_literal: true

class Admin::ChangelogsController < Admin::ResourcesController
  def new
    super
    @resource.date = Date.current
  end

  protected

  def resource_class = Changelog
  def resource_order = { date: :desc }
  def permitted_attributes = %i[date title md]
end
