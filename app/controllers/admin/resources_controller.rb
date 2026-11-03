# frozen_string_literal: true

class Admin::ResourcesController < AdminController
  before_action :load_resource, only: %i[edit update destroy]
  helper_method :resource_class

  def index
    @resources = resource_class.reorder(resource_order)
  end

  def new
    @resource = resource_class.new
  end

  def edit; end

  def create
    @resource = resource_class.new(resource_params)
    save_resource(:new)
  end

  def update
    @resource.assign_attributes(resource_params)
    save_resource(:edit)
  end

  def destroy
    @resource.destroy!
    redirect_to({ action: :index }, notice: :deleted)
  end

  protected

  def load_resource
    @resource = resource_class.find(params[:id])
  end

  def save_resource(failure_action)
    if @resource.save
      redirect_to({ action: :index }, notice: :saved)
    else
      flash.now[:alert] = :check_errors
      render failure_action, status: :unprocessable_content
    end
  end

  def resource_params
    params.require(resource_class.model_name.param_key).permit(permitted_attributes)
  end
end
