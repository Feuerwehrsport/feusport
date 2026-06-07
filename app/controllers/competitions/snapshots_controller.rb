# frozen_string_literal: true

class Competitions::SnapshotsController < CompetitionNestedController
  default_resource

  def create
    @snapshot.assign_attributes(snapshot_params)
    if @snapshot.save
      redirect_to competition_show_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :new, status: :unprocessable_content
    end
  end

  def update
    @snapshot.assign_attributes(snapshot_params)
    if @snapshot.save
      redirect_to competition_show_path, notice: :saved
    else
      flash.now[:alert] = :check_errors
      render action: :edit, status: :unprocessable_content
    end
  end

  def destroy
    @snapshot.destroy
    redirect_to competition_show_path, notice: :deleted
  end

  protected

  def snapshot_params
    params.require(:snapshot).permit(
      :file, :title, :highlight
    )
  end

  def assign_new_resource
    super
    resource_instance.highlight = true unless resource_instance.other_highlights.exists?
  end
end
