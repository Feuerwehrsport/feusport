# frozen_string_literal: true

module Exports::Json::Base
  include Exports::Base
  extend ActiveSupport::Concern

  class_methods do
    def perform(*)
      new(*)
    end
  end

  def bytestream
    @bytestream ||= to_hash.to_json
  end

  def filename
    "#{filename_base}.json"
  end
end
