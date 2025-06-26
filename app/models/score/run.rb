# frozen_string_literal: true

class Score::Run
  include ActiveModel::Model
  include ActiveRecord::AttributeAssignment
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  attr_accessor :list, :run_number
  attr_reader :list_entries

  def initialize(*args)
    super
    @list_entries = @list.entries.where(run: run_number)
    raise ActiveRecord::RecordNotFound if @list_entries.none?
  end

  def persisted?
    true
  end

  def name
    "#{list.name} (Lauf #{run_number})"
  end

  def list_entries_attributes=(attributes)
    attributes.each_value do |entry_attributes|
      entry = list_entries.find { |e| e.track == entry_attributes[:track].to_i }
      entry.assign_attributes(entry_attributes)
    end
  end

  def update(attributes)
    self.list_entries_attributes = attributes[:list_entries_attributes]

    return false unless list_entries.map(&:valid?).all?

    Score::ListEntry.transaction do
      list_entries.all?(&:save!)
    rescue ActiveRecord::Rollback
      false
    end
  end
end
