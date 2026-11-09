# frozen_string_literal: true

# Einschränkung eines Zugangs auf ausgewählte Startlisten (permission selected_results).
# Eine leere Auswahl (z. B. nach dem Löschen der Startlisten) gibt nichts frei, nie alle Startlisten.
module SelectableScoreLists
  extend ActiveSupport::Concern

  included do
    validates :score_list_ids, presence: true, if: :permission_selected_results?
  end

  # Nur Startlisten des eigenen Wettkampfs übernehmen
  def score_list_ids=(ids)
    ids = Array(ids).compact_blank
    ids = competition.score_lists.where(id: ids).ids if competition
    super
  end

  def score_lists
    competition.score_lists.where(id: score_list_ids)
  end
end
