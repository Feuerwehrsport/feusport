# frozen_string_literal: true

require 'axlsx'

module Exports::Xlsx::Base
  include Exports::Base
  extend ActiveSupport::Concern

  class_methods do
    def perform(*)
      instance = new(*)
      instance.perform
      instance
    end
  end

  def bytestream
    @bytestream ||= package.to_stream.read
  end

  def filename
    "#{filename_base}.xlsx"
  end

  protected

  def package
    @package ||= Axlsx::Package.new
  end

  def workbook
    @workbook ||= package.workbook
  end

  def add_worksheet(name, &)
    name = name.to_s.delete(Axlsx::WORKSHEET_NAME_FORBIDDEN_CHARS.join).truncate_bytes(30)
    workbook.add_worksheet(name:, &)
  end
end
