# frozen_string_literal: true

require 'axlsx'

module Exports::Xlsx::Base
  include Exports::Base
  extend ActiveSupport::Concern

  class_methods do
    def perform(*args)
      instance = new(*args)
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
end
