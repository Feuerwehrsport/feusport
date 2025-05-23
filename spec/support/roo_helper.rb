# frozen_string_literal: true

require 'roo'
require 'tempfile'

def parse_xlsx_bytestream(bytestream)
  expect(bytestream).to start_with("PK\x03\x04\x14\x00\x00\x00\b\x00\x00\b!")
  Tempfile.create(['output', '.xlsx']) do |file|
    file.binmode
    file.write(bytestream)
    file.rewind
    Roo::Excelx.new(file.path)
  end
end
