# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.

# generated from version 20230629074606

module SchemaValidations
  extend ActiveSupport::Concern

  included do
    class_attribute :schema_validations_excluded_columns, default: %i[id created_at updated_at type]
    class_attribute :schema_validations_called, default: false

    if defined?(Rails::Railtie) && (Rails.env.development? || Rails.env.test?)
      TracePoint.trace(:end) do |t|
        if t.self.respond_to?(:schema_validations_called) && t.self < ApplicationRecord &&
           !t.self.schema_validations_called
          raise "#{t.self}: schema_validations or skip_schema_validations missing"
        end
      end
    end
  end

  class_methods do
    def schema_validations(exclude: [], schema_table_name: table_name)
      self.schema_validations_called = true
      self.schema_validations_excluded_columns += exclude.map(&:to_sym)
      send("dbv_#{schema_table_name}_validations")
    end

    def skip_schema_validations
      self.schema_validations_called = true
    end


    def dbv_active_storage_attachments_validations
      belongs_to_presence_validations_for([:record_id, :blob_id])
      belongs_to_uniqueness_validations_for([["record_type", "record_id", "name", "blob_id"]])
      uniqueness_validations_for([["record_type", "record_id", "name", "blob_id"]])
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :record_type, {:presence=>{}}
      validates_with_filter :record_id, {:presence=>{}}
      validates_with_filter :blob_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
    end

    def dbv_active_storage_blobs_validations
      belongs_to_presence_validations_for([:byte_size])
      belongs_to_uniqueness_validations_for([["key"]])
      uniqueness_validations_for([["key"]])
      validates_with_filter :key, {:presence=>{}}
      validates_with_filter :filename, {:presence=>{}}
      validates_with_filter :service_name, {:presence=>{}}
      validates_with_filter :byte_size, {:presence=>{}}
      validates_with_filter :byte_size, {:numericality=>{:allow_nil=>true}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
    end

    def dbv_active_storage_variant_records_validations
      belongs_to_presence_validations_for([:blob_id])
      belongs_to_uniqueness_validations_for([["blob_id", "variation_digest"]])
      uniqueness_validations_for([["blob_id", "variation_digest"]])
      validates_with_filter :blob_id, {:presence=>{}}
      validates_with_filter :variation_digest, {:presence=>{}}
    end

    def dbv_bands_validations
      belongs_to_presence_validations_for([:competition_id, :gender])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :gender, {:presence=>{}}
      validates_with_filter :gender, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}}
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :position, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_competitions_validations
      belongs_to_presence_validations_for([:year, :user_id])
      belongs_to_uniqueness_validations_for([["year", "slug"]])
      uniqueness_validations_for([["year", "slug"]])
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :locality, {:presence=>{}}
      validates_with_filter :locality, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :slug, {:presence=>{}}
      validates_with_filter :slug, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :year, {:presence=>{}}
      validates_with_filter :year, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}}
      validates_with_filter :visible, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
      validates_with_filter :date, {:presence=>{}}
      validates_with_filter :date, {:date_in_db_range=>{}}
      validates_with_filter :user_id, {:presence=>{}}
    end

    def dbv_delayed_jobs_validations
      belongs_to_presence_validations_for([:priority, :attempts])
      validates_with_filter :priority, {:presence=>{}}
      validates_with_filter :priority, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}}
      validates_with_filter :attempts, {:presence=>{}}
      validates_with_filter :attempts, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}}
      validates_with_filter :handler, {:presence=>{}}
      validates_with_filter :run_at, {:date_time_in_db_range=>{}}
      validates_with_filter :locked_at, {:date_time_in_db_range=>{}}
      validates_with_filter :failed_at, {:date_time_in_db_range=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_documents_validations
      validates_with_filter :title, {:presence=>{}}
      validates_with_filter :title, {:length=>{:allow_nil=>true, :maximum=>200}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_users_validations
      belongs_to_presence_validations_for([:sign_in_count, :failed_attempts])
      belongs_to_uniqueness_validations_for([["confirmation_token"], ["email"], ["reset_password_token"], ["unlock_token"]])
      uniqueness_validations_for([["confirmation_token"], ["email"], ["reset_password_token"], ["unlock_token"]])
      validates_with_filter :email, {:presence=>{}}
      validates_with_filter :encrypted_password, {:presence=>{}}
      validates_with_filter :reset_password_sent_at, {:date_time_in_db_range=>{}}
      validates_with_filter :remember_created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :sign_in_count, {:presence=>{}}
      validates_with_filter :sign_in_count, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}}
      validates_with_filter :current_sign_in_at, {:date_time_in_db_range=>{}}
      validates_with_filter :last_sign_in_at, {:date_time_in_db_range=>{}}
      validates_with_filter :confirmed_at, {:date_time_in_db_range=>{}}
      validates_with_filter :confirmation_sent_at, {:date_time_in_db_range=>{}}
      validates_with_filter :failed_attempts, {:presence=>{}}
      validates_with_filter :failed_attempts, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}}
      validates_with_filter :locked_at, {:date_time_in_db_range=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :user_manager, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :competition_manager, {:inclusion=>{:in=>[true, false], :message=>:blank}}
    end


    def validates_with_filter(attribute, options)
      return if attribute.to_sym.in?(schema_validations_excluded_columns)

      validates attribute, options
    end

    def belongs_to_presence_validations_for(not_null_columns)
      reflect_on_all_associations(:belongs_to).each do |association|
        if not_null_columns.include?(association.foreign_key.to_sym)
          validates association.name, presence: true
          schema_validations_excluded_columns.push(association.foreign_key.to_sym)
        end
      end
    end

    def bad_uniqueness_validations_for(unique_indexes)
      unique_indexes.each do |names|
        names.each do |name|
          next if name.to_sym.in?(schema_validations_excluded_columns)

          raise "Unique index with where clause is outside the scope of this gem.\n\n" \
                "You can exclude this column: `schema_validations exclude: [:#{name}]`"
        end
      end
    end

    def belongs_to_uniqueness_validations_for(unique_indexes)
      reflect_on_all_associations(:belongs_to).each do |association|
        dbv_uniqueness_validations_for(unique_indexes, foreign_key: association.foreign_key.to_s,
                                                       column: association.name)
      end
    end

    def uniqueness_validations_for(unique_indexes)
      unique_indexes.each do |names|
        names.each do |name|
          dbv_uniqueness_validations_for(unique_indexes, foreign_key: name, column: name)
        end
      end
    end

    def dbv_uniqueness_validations_for(unique_indexes, foreign_key:, column:)
      unique_indexes.each do |names|
        next unless foreign_key.in?(names)
        next if column.to_sym.in?(schema_validations_excluded_columns)

        scope = (names - [foreign_key]).map(&:to_sym)
        options = { allow_nil: true }
        options[:scope] = scope if scope.any?
        options[:if] = (proc do |record|
          if scope.all? { |scope_sym| record.public_send(:"#{scope_sym}?") }
            record.public_send(:"#{foreign_key}_changed?")
          else
            false
          end
        end)

        validates column, uniqueness: options
      end
    end
  end

  class DateTimeInDbRangeValidator < ActiveModel::EachValidator
    def validate_each(record, attr_name, value)
      return if value.nil?
      return unless value.is_a?(DateTime) || value.is_a?(Time)
      return if value.year.between?(-4711, 294275) # see https://www.postgresql.org/docs/9.3/datatype-datetime.html

      record.errors.add(attr_name, :invalid, options)
    end
  end

  class DateInDbRangeValidator < ActiveModel::EachValidator
    def validate_each(record, attr_name, value)
      return if value.nil?
      return unless value.is_a?(Date)
      return if value.year.between?(-4711, 5874896) # see https://www.postgresql.org/docs/9.3/datatype-datetime.html

      record.errors.add(attr_name, :invalid, options)
    end
  end
end
