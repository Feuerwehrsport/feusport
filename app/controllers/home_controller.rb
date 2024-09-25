# frozen_string_literal: true

class HomeController < ApplicationController
  def home
    @years = Competition.accessible_by(current_ability)
                        .group(:year).order(year: :desc).pluck(:year)

    @competitions = Competition.accessible_by(current_ability)
    @competitions = if params[:year].blank?
                      @competitions.current
                    else
                      @competitions.where("DATE_PART('year', date) = ?", params[:year].to_i)
                    end

    @current_dates = (Date.current - 3.days..Date.current + 3.days)
  end

  def info; end
  def help; end

  def disseminators
    @disseminators = Disseminator.reorder(:name)
  end
end
