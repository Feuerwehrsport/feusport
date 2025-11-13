# frozen_string_literal: true

class Competitions::SimpleAccessLoginsController < CompetitionNestedController
  def new
    @simple_access = SimpleAccess.new(competition: @competition)
  end

  def create
    @simple_access = @competition.simple_accesses.find_by(name: simple_access_params[:name])

    if @simple_access&.authenticate(simple_access_params[:password])
      session["simple_access_#{@competition.id}"] = @simple_access.id
      flash[:notice] = 'Login mit Gastzugang erfolgreich'
      redirect_to competition_show_path
    else
      @simple_access = SimpleAccess.new(competition: @competition)
      @simple_access.errors.add(:password, :invalid)

      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def destroy
    session.delete("simple_access_#{@competition.id}")
    flash[:notice] = 'Login mit Gastzugang beendet'
    redirect_to competition_show_path
  end

  protected

  def resource_class
    SimpleAccess
  end
  helper_method :resource_class

  def simple_access_params
    params.require(:simple_access_login).permit(
      :name, :password
    )
  end
end
