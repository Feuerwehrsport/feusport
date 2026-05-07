# frozen_string_literal: true

class Users::InterestsController < ApplicationController
  def edit
    authorize!(:edit, current_user)
  end

  def update
    authorize!(:edit, current_user)

    current_user.assign_attributes(user_params)
    if current_user.save
      redirect_to root_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  protected

  def user_params
    params.require(:user).permit(
      :lat, :lng, :distance, feature_ids: []
    )
  end
end
