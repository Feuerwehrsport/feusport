# frozen_string_literal: true

class Admin::UsersController < AdminController
  before_action :load_user, except: %i[index]

  def index
    users = User.includes(:user_accesses).reorder(created_at: :desc, name: :asc, id: :asc)
    users = users.where('users.name ILIKE :q OR users.email ILIKE :q', q: search_term) if params[:q].present?
    @users = paginate(users)
  end

  def unlock
    @user.unlock_access!
    redirect_back_to_index notice: :saved
  end

  def disable
    return redirect_back_to_index(alert: :not_yourself) if @user == current_user

    @user.update!(disabled_at: Time.current)
    redirect_back_to_index notice: :saved
  end

  def enable
    @user.update!(disabled_at: nil)
    redirect_back_to_index notice: :saved
  end

  def confirm
    @user.confirm
    redirect_back_to_index notice: :saved
  end

  def reset_password
    @user.send_reset_password_instructions
    redirect_back_to_index notice: :password_reset_sent
  end

  protected

  def load_user
    @user = User.find(params[:id])
  end

  def redirect_back_to_index(flash)
    redirect_to admin_users_path(params.permit(:q, :page)), flash
  end
end
