# frozen_string_literal: true

class Competitions::DisciplinesController < CompetitionNestedController
  default_resource

  def index
    send_pdf(Exports::Pdf::Disciplines, args: [@competition])
    send_xlsx(Exports::Xlsx::Disciplines, args: [@competition])
  end

  def create
    @discipline.assign_attributes(discipline_params)
    if @discipline.save
      redirect_to competition_disciplines_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @discipline.assign_attributes(discipline_params)
    if @discipline.save
      redirect_to competition_disciplines_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @discipline.destroy
    redirect_to competition_disciplines_path, notice: :deleted
  end

  protected

  def discipline_params
    params.require(:discipline).permit(
      :key, :name, :short_name, :single_discipline, :like_fire_relay
    )
  end
end
