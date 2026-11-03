# frozen_string_literal: true

class AdminController < ApplicationController
  PER_PAGE = 20

  before_action :require_admin!

  protected

  def paginate(scope)
    @page_count = [(scope.count / PER_PAGE.to_f).ceil, 1].max
    @page = params[:page].to_i.clamp(1, @page_count)
    scope.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
  end

  def search_term
    "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
  end
end
