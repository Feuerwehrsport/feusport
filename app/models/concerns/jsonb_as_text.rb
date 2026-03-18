# frozen_string_literal: true

module JsonbAsText
  extend ActiveSupport::Concern

  class_methods do
    def jsonb_as_text(field)
      attr_writer "#{field}_text"

      define_method("#{field}_text") do
        instance_variable_get("@#{field}_text") || JSON.pretty_generate(send(field))
      end

      before_validation do
        next if instance_variable_get("@#{field}_text").blank?

        send("#{field}=", JSON.parse(instance_variable_get("@#{field}_text")))
      rescue JSON::ParserError
        errors.add(:"#{field}_text", 'ist kein gültiges JSON')
      end
    end
  end
end
