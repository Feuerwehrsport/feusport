# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationCable::Connection do
  it 'connects without identification' do
    connect '/cable'
    expect(connection).to be_a(described_class)
  end
end
