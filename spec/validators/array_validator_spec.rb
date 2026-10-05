# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArrayValidator do
  let(:model_class) do
    Class.new do
      include ActiveModel::Model

      def self.name
        'ArrayValidatorTestModel'
      end

      attr_accessor :values, :custom

      validates :values, array: { of: String, min: 1, in: %w[a b] }
      validates :custom, array: { message: 'ist falsch' }
    end
  end

  def errors_for(values, custom: [])
    model = model_class.new(values:, custom:)
    model.valid?
    model.errors
  end

  it 'accepts valid arrays' do
    expect(errors_for(%w[a b])).to be_empty
  end

  it 'requires array' do
    expect(errors_for('a')[:values]).to eq ['must be an array']
  end

  it 'checks minimum size' do
    expect(errors_for([])[:values]).to eq ['must contain at least 1 element(s)']
  end

  it 'checks allowed values' do
    expect(errors_for(%w[a c])[:values]).to eq ['must all in ["a", "b"]']
  end

  it 'checks element class' do
    expect(errors_for(['a', 1])[:values]).to contain_exactly(
      'must all in ["a", "b"]',
      'must contain only String values',
    )
  end

  it 'uses custom message' do
    expect(errors_for(%w[a], custom: nil)[:custom]).to eq ['ist falsch']
  end
end
