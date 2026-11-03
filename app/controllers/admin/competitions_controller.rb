# frozen_string_literal: true

class Admin::CompetitionsController < AdminController
  before_action :load_competition, except: %i[index]

  def index
    competitions = Competition.includes(:users).reorder(date: :desc, name: :asc, id: :asc)
    if params[:q].present?
      competitions = competitions.where('competitions.name ILIKE :q OR competitions.place ILIKE :q ' \
                                        'OR CAST(competitions.year AS text) = :year',
                                        q: search_term, year: params[:q].strip)
    end
    @competitions = paginate(competitions)
  end

  def join
    @competition.user_accesses.create_with(registration_mail_info: false).find_or_create_by!(user: current_user)
    redirect_to helpers.competition_path(@competition), notice: :competition_joined
  end

  def leave
    @competition.user_accesses.where(user: current_user).destroy_all
    redirect_to admin_competitions_path(params.permit(:q, :page)), notice: :competition_left
  end

  protected

  def load_competition
    @competition = Competition.find(params[:id])
  end
end
