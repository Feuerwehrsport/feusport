# frozen_string_literal: true

class Competitions::CreationsController < ApplicationController
  def new
    authorize!(:create, Competition)
    @competition = Competition.new(wko: Wko.current)
    @competition.users.push(current_user)
    authorize!(:create, @competition)
  end

  def create
    authorize!(:create, Competition)
    @competition = Competition.new
    @competition.users.push(current_user)
    authorize!(:create, @competition)
    @competition.assign_attributes(competition_params)
    if @competition.save
      Certificates::Template.create_example(@competition)
      TeamMarker.create_example(@competition)
      redirect_to competition_show_path(slug: @competition.slug, year: @competition.year), notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  protected

  def competition_params
    params.require(:competition).permit(
      :name, :date, :place, :wko_id
    )
  end
end
