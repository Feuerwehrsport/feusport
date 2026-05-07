# frozen_string_literal: true

module LngLatSupport
  def lat
    lnglat&.latitude
  end

  def lng
    lnglat&.longitude
  end

  def lat=(value)
    @lat = value
    set_lnglat
  end

  def lng=(value)
    @lng = value
    set_lnglat
  end

  private

  def set_lnglat
    if @lat.blank? || @lng.blank?
      self.lnglat = nil
    else
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      self.lnglat = factory.point(@lng.to_f, @lat.to_f)
    end
  end
end
