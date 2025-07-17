# frozen_string_literal: true

class Competitions::TeamsController < CompetitionNestedController
  default_resource

  def index
    send_pdf(Exports::Pdf::Teams) { [@competition, can?(:manage, @competition)] }
    send_xlsx(Exports::Xlsx::Teams) { [@competition, can?(:manage, @competition)] }
  end

  def without_statistics_connection
    @team_suggestions = @teams.where(fire_sport_statistics_team_id: nil).map do |team|
      FireSportStatistics::TeamSuggestion.new(team)
    end

    redirect_to(action: :index) if @team_suggestions.blank?
  end

  def create
    @team.assign_attributes(team_params)
    if @team.save
      CompetitionMailer.with(team: @team).registration_team.deliver_later if @team.users.exists?

      if @team.requests.present?
        redirect_to edit_assessment_requests_competition_team_path(id: @team.id), notice: :saved
      else
        redirect_to competition_team_path(id: @team.id), notice: :saved
      end
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_entity
    end
  end

  def update
    @team.assign_attributes(team_params)
    if @team.save
      if params[:return_to] == 'without_statistics_connection'
        redirect_to without_statistics_connection_competition_teams_path, notice: :saved
      else
        redirect_to competition_team_path(id: @team.id), notice: :saved
      end
    else
      flash.now[:alert] = :check_errors
      if params[:form] == 'edit_assessment_requests'
        render action: :edit_assessment_requests, status: :unprocessable_entity
      else
        render action: :edit, status: :unprocessable_entity
      end
    end
  end

  protected

  def can_sub_edit_team?
    @can_sub_edit_team ||= can?(:sub_edit, @team)
  end
  helper_method :can_sub_edit_team?

  def team_params
    return {} unless params.key?(:team)

    params.require(:team).permit(
      :name, :shortcut, :number, :band_id, :fire_sport_statistics_team_id, :registration_hint, :certificate_name,
      :lottery_number,
      tags: [],
      requests_attributes: %i[assessment_type relay_count _destroy assessment_id id]
    )
  end

  def assign_new_resource
    band = @competition.bands.find_by(id: params[:band_id])
    return redirect_to({ action: :index }, notice: 'Bitte wähle eine Wertungsgruppe aus') if band.blank?

    self.resource_instance = resource_class.new(competition: @competition, band:)
    return if can?(:manage, @competition)

    resource_instance.user_team_accesses.build(user: current_user, competition: @competition)
    resource_instance.registration_hint =
      "Mannschaftsleiter: #{current_user.name}\n" \
      "E-Mail-Adresse: #{current_user.email}\n" \
      "Telefonnummer: #{current_user.phone_number}\n"
  end
end
