# frozen_string_literal: true

module Adressevaelger
  # Resolved Danish address from Adressevælger.
  ResolvedAddress = Data.define(
    :line1,
    :line2,
    :postal_code,
    :city,
    :country,
    :etage,
    :doer,
    :address_provider,
    :external_address_id,
    :external_building_id,
    :latitude,
    :longitude,
    :coord_easting,
    :coord_northing,
    :coord_epsg
  )
end
