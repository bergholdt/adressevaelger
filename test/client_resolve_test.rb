# frozen_string_literal: true

require "test_helper"
require "json"
require "net/http"

class ClientResolveTest < Minitest::Test
  VESTERGADE_1_ID = "0a3f507b-24a4-32b8-e044-0003ba298018"

  def test_resolve_husnummer_maps_fields_and_etrs89
    http = lambda do |uri, _request|
      assert_equal "/husnumre/#{VESTERGADE_1_ID}", uri.path

      ok_json(
        "status" => "ok",
        "husnummer" => {
          "id_lokalid" => VESTERGADE_1_ID,
          "husnummertekst" => "1",
          "vejnavn" => "Vestergade",
          "adgangspunkt" => {
            "koordinater" => { "x" => 724_533.07, "y" => 6_176_026.84 }
          },
          "postnummer" => { "postnr" => "1456", "navn" => "København K" }
        }
      )
    end

    resolved = Adressevaelger::Client.new(http: http).resolve(id: VESTERGADE_1_ID, type: "husnummer")

    assert_equal "Vestergade 1", resolved.line1
    assert_equal "1456", resolved.postal_code
    assert_equal "København K", resolved.city
    assert_equal "DK", resolved.country
    assert_equal "adressevaelger", resolved.address_provider
    assert_equal VESTERGADE_1_ID, resolved.external_building_id
    assert_in_delta 724_533.07, resolved.coord_easting, 0.01
    assert_in_delta 6_176_026.84, resolved.coord_northing, 0.01
    assert_equal 25_832, resolved.coord_epsg
  end

  def test_resolve_adresse_uses_adresser_path
    http = lambda do |uri, _request|
      assert_equal "/adresser/addr-1", uri.path
      ok_json(
        "status" => "ok",
        "adresse" => {
          "id_lokalid" => "addr-1",
          "husnummer_id" => "hus-1",
          "vejnavn" => "Nørrebrogade",
          "husnr" => "10",
          "etagebetegnelse" => "2",
          "doerbetegnelse" => "tv",
          "postnummer" => { "nr" => "2200", "navn" => "København N" }
        }
      )
    end

    resolved = Adressevaelger::Client.new(http: http).resolve(id: "addr-1", type: "adresse")

    assert_equal "Nørrebrogade 10", resolved.line1
    assert_equal "2", resolved.etage
    assert_equal "tv", resolved.doer
    assert_equal "addr-1", resolved.external_address_id
    assert_equal "hus-1", resolved.external_building_id
  end

  private

  def ok_json(payload)
    Net::HTTPOK.new("1.1", "200", "OK").tap do |response|
      response.define_singleton_method(:body) { JSON.generate(payload) }
    end
  end
end
