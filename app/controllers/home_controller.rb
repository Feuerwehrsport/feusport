# frozen_string_literal: true

class HomeController < ApplicationController
  def home
    @years = Competition.accessible_by(current_ability)
                        .group(:year).order(year: :desc).pluck(:year)

    @competitions = Competition.accessible_by(current_ability)
    @competitions = if params[:year].blank?
                      @competitions.current
                    else
                      @competitions.where(year: params[:year].to_i)
                    end

    @current_dates = ((Date.current - 3.days)..(Date.current + 3.days))
  end

  def info; end
  def help; end
  def help_assessment; end

  def changelogs
    @changelogs = Changelog.reorder(date: :desc)
  end

  def disseminators
    @disseminators = Disseminator.reorder(:name)
  end
end
