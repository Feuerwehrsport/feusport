# frozen_string_literal: true

class Api::V1::ListEntriesController < Api::V1::BaseController
  def update
    entry = Score::ListEntry.where(list: accessible_lists).find(params[:id])

    entry.with_lock do
      if params[:version] == entry.api_version
        entry.assign_attributes(entry_params(entry.list))
        save_entry(entry)
      else
        render_error(:conflict, :conflict, entry: entry.api_json)
      end
    end
  end

  private

  # Felder, die zur Art der Startliste nicht passen, werden ignoriert
  def entry_params(list)
    time_fields = list.separate_target_times? ? %i[time_left_target time_right_target] : %i[time]
    params.permit(:result_type, *time_fields)
  end

  def save_entry(entry)
    if entry.save(context: :api)
      render json: entry.api_json
    else
      fields = entry.errors.details.transform_values { |details| details.pluck(:error).uniq }
      render_error(:unprocessable_content, :validation_failed, fields:)
    end
  end
end
