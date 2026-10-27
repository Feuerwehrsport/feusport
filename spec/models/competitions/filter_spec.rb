# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Competitions::Filter do
  let(:din) { create(:feature, :din) }
  let(:tgl) { create(:feature, :tgl) }
  let!(:rostock) { create(:competition, features: [din], lat: '54.08', lng: '12.13') }
  let!(:berlin) do
    create(:competition, name: 'Berlin-Cup', place: 'Berlin', features: [tgl], lat: '52.52', lng: '13.40')
  end
  let!(:without_location) { create(:competition, name: 'Irgendwo', features: [din, tgl]) }
  let(:rostock_lnglat) { RGeo::Geographic.spherical_factory(srid: 4326).point(12.1, 54.1) }

  def ids(filter)
    filter.apply(Competition.all).pluck(:id)
  end

  it 'returns everything without filter' do
    filter = described_class.new
    expect(filter).not_to be_active
    expect(ids(filter)).to contain_exactly(rostock.id, berlin.id, without_location.id)
    expect(filter.to_params).to eq({})
  end

  it 'filters by features' do
    filter = described_class.new(feature_ids: ['', din.id])
    expect(filter).to be_active
    expect(ids(filter)).to contain_exactly(rostock.id, without_location.id)
    expect(filter.to_params).to eq(feature_ids: [din.id])

    expect(ids(described_class.new(feature_ids: [din.id, tgl.id])))
      .to contain_exactly(rostock.id, berlin.id, without_location.id)
  end

  it 'filters by distance only with location' do
    expect(ids(described_class.new(distance: 50))).to contain_exactly(rostock.id, berlin.id, without_location.id)

    filter = described_class.new(distance: '50', lnglat: rostock_lnglat)
    expect(filter).to be_active
    expect(ids(filter)).to contain_exactly(rostock.id)
    expect(filter.to_params).to eq(distance: 50)

    expect(ids(described_class.new(distance: 300, lnglat: rostock_lnglat))).to contain_exactly(rostock.id, berlin.id)
  end

  it 'sanitizes sort' do
    expect(described_class.new(sort: 'published')).to be_sort_published
    expect(described_class.new(sort: 'evil').sort).to eq 'date'
    expect(described_class.new(sort: 'published').to_params).to eq(sort: 'published')
  end

  it 'counts customizations' do
    expect(described_class.new).not_to be_customized
    expect(described_class.new(sort: 'published')).to be_customized
    expect(described_class.new(sort: 'published').customizations_count).to eq 1
    filter = described_class.new(sort: 'published', feature_ids: [din.id, tgl.id], distance: 5, lnglat: rostock_lnglat)
    expect(filter.customizations_count).to eq 4
  end

  it 'builds from user interests' do
    user = build(:user, features: [tgl], distance: 300, lat: '54.1', lng: '12.1')
    filter = described_class.for_user(user)
    expect(ids(filter)).to contain_exactly(berlin.id)
  end
end
