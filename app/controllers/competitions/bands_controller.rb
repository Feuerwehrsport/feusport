# frozen_string_literal: true

class Competitions::BandsController < CompetitionNestedController
  default_resource

  def index
    send_pdf(Exports::Pdf::Bands, args: [@competition])
    send_xlsx(Exports::Xlsx::Bands, args: [@competition])
  end

  def edit
    if params[:move] == 'up'
      @band.move_higher
      redirect_to action: :index
    elsif params[:move] == 'down'
      @band.move_lower
      redirect_to action: :index
    end
  end

  def create
    @band.assign_attributes(band_params)
    if @band.save
      redirect_to competition_bands_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @band.assign_attributes(band_params)
    if @band.save
      redirect_to competition_bands_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @band.destroy
    redirect_to competition_bands_path, notice: :deleted
  end

  protected

  def band_params
    params.require(:band).permit(
      :name, :gender, :person_tag_names, :team_tag_names
    )
  end
end
