# frozen_string_literal: true

require "test_helper"

class Etrs89ToWgs84Test < Minitest::Test
  # Control points from `cs2cs EPSG:25832 EPSG:4326` (PROJ 9.x; lon/lat order for rgeo).
  CONTROL = {
    aarhus: { easting: 575_000.0, northing: 6_221_000.0, lat: 56.12816616, lon: 10.20657304 },
    copenhagen: { easting: 725_000.0, northing: 6_175_000.0, lat: 55.66858987, lon: 12.57792613 }
  }.freeze

  def setup
    skip "rgeo-proj4 / PROJ not available" unless Adressevaelger::Etrs89ToWgs84.available?
  end

  def test_transforms_aarhus_utm32n_control_point_to_wgs84
    point = CONTROL[:aarhus]
    lat, lon = Adressevaelger::Etrs89ToWgs84.call(easting: point[:easting], northing: point[:northing])

    assert_in_delta point[:lat], lat, 1e-6
    assert_in_delta point[:lon], lon, 1e-6
  end

  def test_transforms_copenhagen_utm32n_control_point_to_wgs84
    point = CONTROL[:copenhagen]
    lat, lon = Adressevaelger::Etrs89ToWgs84.call(easting: point[:easting], northing: point[:northing])

    assert_in_delta point[:lat], lat, 1e-6
    assert_in_delta point[:lon], lon, 1e-6
  end
end
