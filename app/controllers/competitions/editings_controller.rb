# frozen_string_literal: true

class Competitions::EditingsController < CompetitionNestedController
  def edit; end

  def update
    @competition.assign_attributes(competition_params)
    if @competition.save
      redirect_to competition_show_path(id: @competition.slug, year: @competition.year), notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  protected

  def competition_params
    params.require(:competition).permit(
      :name, :date, :place, :description, :lottery_numbers, :show_bib_numbers, :flyer_headline, :flyer_content, :wko_id
    )
  end
end
