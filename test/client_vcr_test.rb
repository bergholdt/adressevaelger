# frozen_string_literal: true

require "test_helper"

# Integration-style: replay recorded Adressevælger HTTP.
# Re-record: `VCR_RECORD=all bundle exec rake test TEST=test/client_vcr_test.rb`
# Never hand-write cassette bodies.
class ClientVcrTest < Minitest::Test
  VESTERGADE_1_ID = "0a3f507b-24a4-32b8-e044-0003ba298018"

  def test_autocomplete_returns_dar_suggestions_from_adressevaelger
    VCR.use_cassette("autocomplete_vestergade") do
      suggestions = Adressevaelger::Client.new.autocomplete("Vestergade 1")

      assert_operator suggestions.size, :>=, 1
      assert_equal "adressevaelger", suggestions.first.provider
      refute_nil suggestions.first.id
      assert_match(/Vestergade/i, suggestions.first.label)
    end
  end

  def test_resolve_husnummer_includes_etrs89_and_optional_wgs84
    VCR.use_cassette("resolve_vestergade_1") do
      resolved = Adressevaelger::Client.new.resolve(id: VESTERGADE_1_ID, type: "husnummer")

      assert_equal "Vestergade 1", resolved.line1
      assert_equal "1456", resolved.postal_code
      assert_equal "København K", resolved.city
      assert_equal "adressevaelger", resolved.address_provider
      refute_nil resolved.coord_easting
      refute_nil resolved.coord_northing
      assert_equal 25_832, resolved.coord_epsg

      if Adressevaelger::Etrs89ToWgs84.available?
        refute_nil resolved.latitude
        refute_nil resolved.longitude
      end
    end
  end
end
