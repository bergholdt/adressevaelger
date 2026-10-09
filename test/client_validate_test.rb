# frozen_string_literal: true

require "test_helper"
require "json"
require "net/http"

class ClientValidateTest < Minitest::Test
  def test_validate_returns_empty_for_blank_text
    client = Adressevaelger::Client.new(http: ->(*) { flunk "should not call HTTP" })

    assert_equal [], client.validate("")
    assert_equal [], client.validate(nil)
  end

  def test_validate_maps_vask_resultater
    http = lambda do |uri, _request|
      assert_equal "/vask/", uri.path
      assert_includes uri.query, "adresse=Vestergade+1"

      ok_json(
        "resultater" => [
          {
            "adresse_id_lokalid" => "addr-9",
            "betegnelse" => "Vestergade 1, 1456 København K",
            "type" => "adresse"
          }
        ]
      )
    end

    suggestions = Adressevaelger::Client.new(http: http).validate("Vestergade 1")

    assert_equal 1, suggestions.size
    assert_equal "addr-9", suggestions.first.id
    assert_equal "adresse", suggestions.first.type
    assert_match(/Vestergade/, suggestions.first.label)
  end

  def test_vask_aliases_validate
    http = lambda do |_uri, _request|
      ok_json("resultater" => [])
    end

    assert_equal [], Adressevaelger::Client.new(http: http).vask("Vestergade 1")
  end

  private

  def ok_json(payload)
    Net::HTTPOK.new("1.1", "200", "OK").tap do |response|
      response.define_singleton_method(:body) { JSON.generate(payload) }
    end
  end
end
