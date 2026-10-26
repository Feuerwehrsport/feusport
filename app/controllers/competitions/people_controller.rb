# frozen_string_literal: true

class Competitions::PeopleController < CompetitionNestedController
  default_resource
  skip_authorize_resource :person, only: %i[new create]

  def index
    @without_statistics_id = @people.where(fire_sport_statistics_person_id: nil)

    send_pdf(Exports::Pdf::People, args: [@competition])
    send_xlsx(Exports::Xlsx::People, args: [@competition])
  end

  def without_statistics_connection
    @person_suggestions = @people.where(fire_sport_statistics_person_id: nil).sort.map do |person|
      FireSportStatistics::PersonSuggestion.new(person)
    end

    redirect_to(action: :index) if @person_suggestions.blank?
  end

  def edit_assessment_requests
    return unless request.xhr?

    render json: { content: render_to_string(partial: 'edit_assessment_requests_form') }
  end

  def create
    @person.assign_attributes(person_params)
    assign_team_from_name
    authorize_person_team!
    if @person.save
      CompetitionMailer.with(person: @person).registration_person.deliver_later if @person.users.exists?
      send_new_team_mail

      if params[:return_to] == 'team'
        redirect_to competition_team_path(id: @person.team_id, jump_to: 'people-table'), notice: :saved
      else
        redirect_to competition_person_path(id: @person.id), notice: :saved
      end
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @person.assign_attributes(person_params)
    @person.check_band_limit = !can?(:manage, @competition)
    assign_team_from_name
    authorize_person_team!
    if @person.save
      send_new_team_mail
      if params[:return_to] == 'team'
        redirect_to competition_team_path(id: @person.team_id, jump_to: 'people-table'), notice: :saved
      elsif params[:return_to] == 'without_statistics_connection'
        redirect_to without_statistics_connection_competition_people_path, notice: :saved
      else
        redirect_to competition_person_path(id: @person.id), notice: :saved
      end
    else
      flash.now[:alert] = :check_errors
      if params[:form] == 'edit_assessment_requests'
        render action: :edit_assessment_requests, status: :unprocessable_content
      else
        render action: :edit, status: :unprocessable_content
      end
    end
  end

  def destroy
    @person.destroy
    redirect_to competition_people_path, notice: :deleted
  end

  protected

  def assign_team_from_name
    name = @person.create_team_name.to_s.strip
    return if name.blank? || @person.team&.persisted?

    admin = can?(:manage, @competition)
    teams = @person.band.teams.where('LOWER(TRIM(teams.name)) = ?', name.downcase).to_a
    @person.team = admin ? teams.first : teams.find { |team| can?(:sub_edit, team) }
    return if @person.team.present?
    return @person.create_team_name_error = :team_name_taken if teams.any?

    @new_team = @person.build_team(competition: @competition, band: @person.band, name:, shortcut: name.first(12),
                                   disable_autocreate_assessment_requests: true)
    return if admin
    return @person.create_team_name_error = :team_registration_closed unless can?(:create, @new_team)
    return @person.create_team_name_error = :teams_limit_reached if @person.band.teams_limit_reached?

    @new_team.user_team_accesses.build(user: current_user, competition: @competition)
  end

  def send_new_team_mail
    return unless @new_team&.persisted? && @new_team.users.exists?

    CompetitionMailer.with(team: @new_team).registration_team.deliver_later
  end

  def authorize_person_team!
    authorize!(:sub_edit, @person.team) if @person.team.present? && @person.team_id_changed?
  end

  def team_from_param
    return @team_from_param if defined?(@team_from_param)

    @team_from_param = @competition.teams.find_by(id: params[:team].presence || person_params[:team_id])
  end

  def person_params
    return {} unless params.key?(:person)

    params.require(:person).permit(
      :first_name, :last_name, :team_id, :fire_sport_statistics_person_id, :registration_hint,
      :registration_order, :bib_number, :create_team_name,
      tags: [],
      requests_attributes: %i[assessment_type _destroy assessment_id id
                              group_competitor_order single_competitor_order
                              competitor_order]
    )
  end

  def assign_new_resource
    self.resource_instance = resource_class.new(competition: @competition)
    resource_instance.assign_attributes(team: team_from_param, band: team_from_param.band) if team_from_param.present?
    resource_instance.band ||= @competition.bands.find_by(id: params[:band_id])

    if resource_instance.band.blank?
      return redirect_to({ action: :index }, notice: 'Bitte wähle eine Wertungsgruppe aus')
    end

    return if can?(:manage, @competition)

    resource_instance.check_band_limit = true
    if action_name == 'new' && resource_instance.band.people_limit_reached?
      return redirect_to({ action: :index }, alert: :band_full)
    end
    return if can?(:edit, resource_instance.team)

    resource_instance.user_person_accesses.build(user: current_user, competition: @competition)
    authorize!(:create, resource_instance)

    resource_instance.registration_hint =
      "Mannschaftsleiter: #{current_user.name}\n" \
      "E-Mail-Adresse: #{current_user.email}\n" \
      "Telefonnummer: #{current_user.phone_number}\n"
  end
end
