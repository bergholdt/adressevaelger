# frozen_string_literal: true

module Adressevaelger
  # ETRS89/UTM32N (EPSG:25832) → WGS84 (EPSG:4326) via PROJ (`rgeo-proj4`).
  #
  # Soft-requires `rgeo/proj4`. Returns `nil` when the optional gem is not
  # installed or PROJ cannot load; resolve still returns ETRS89 easting/northing.
  module Etrs89ToWgs84
    module_function

    def available?
      return @available if defined?(@available)

      begin
        require "rgeo/proj4"
        @source = RGeo::CoordSys::Proj4.create(25_832)
        @target = RGeo::CoordSys::Proj4.create(4326)
        @available = true
      rescue LoadError, StandardError
        @available = false
      end
    end

    def call(easting:, northing:)
      return nil unless available?

      lon, lat = RGeo::CoordSys::Proj4.transform_coords(
        @source,
        @target,
        easting.to_f,
        northing.to_f,
        nil
      )

      [lat.round(7), lon.round(7)]
    end
  end
end
