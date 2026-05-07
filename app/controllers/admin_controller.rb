# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :require_admin!
end
