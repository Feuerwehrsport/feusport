# frozen_string_literal: true

class MaxEntriesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    reverse_key = options.fetch(:reverse_key)
    max         = options.fetch(:max)
    add_to      = options.fetch(:add_to) || attribute

    relation = value.public_send(reverse_key)

    count =
      if record.persisted?
        relation.where.not(id: record.id).count + 1
      else
        relation.count + 1
      end

    return if count <= max

    record.errors.add(
      add_to,
      :max_entries_created,
      count: max,
    )
  end
end
