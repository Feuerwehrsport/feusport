# frozen_string_literal: true

# Rails schreibt `*_ids=` bei gespeicherten Datensätzen sofort in die Join-Tabelle,
# also bevor `same_competition` beim Speichern greifen kann. Deshalb werden die IDs
# schon beim Zuweisen auf Datensätze des eigenen Wettkampfs eingeschränkt.
module CompetitionScopedIds
  extend ActiveSupport::Concern

  class_methods do
    # competition_scoped_ids :assessments, results: :score_results
    def competition_scoped_ids(*associations, **mapping)
      associations.index_with(&:itself).merge(mapping).each do |association, competition_association|
        define_method(:"#{association.to_s.singularize}_ids=") do |ids|
          ids = Array(ids).compact_blank
          ids = competition.public_send(competition_association).where(id: ids).ids if competition
          super(ids)
        end
      end
    end
  end
end
