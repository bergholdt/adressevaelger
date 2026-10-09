# frozen_string_literal: true

require "test_helper"
require "json"
require "net/http"

class ClientAutocompleteTest < Minitest::Test
  def test_default_base_url_is_adressevaelger_dk
    assert_equal "https://adressevaelger.dk", Adressevaelger::Client::DEFAULT_BASE_URL
  end

  def test_autocomplete_returns_empty_for_short_query
    client = Adressevaelger::Client.new(http: ->(*) { flunk "should not call HTTP" })

    assert_equal [], client.autocomplete("ab")
    assert_equal [], client.autocomplete("")
    assert_equal [], client.autocomplete(nil)
  end

  def test_autocomplete_maps_fund_to_suggestions
    http = lambda do |uri, _request|
      assert_includes uri.path, "/husnumre/soeg"
      assert_includes uri.query, "tekst=Badevej"
      assert_includes uri.query, "token=test-token-xx"

      ok_json(
        "status" => "ok",
        "fund" => [
          {
            "type" => "husnummer",
            "id" => "abc-123",
            "titel" => "Badevej 1, 8000 Aarhus C"
          }
        ]
      )
    end

    suggestions = Adressevaelger::Client.new(http: http, token: "test-token-xx").autocomplete("Badevej")

    assert_equal 1, suggestions.size
    assert_equal "abc-123", suggestions.first.id
    assert_equal "husnummer", suggestions.first.type
    assert_match(/Badevej/, suggestions.first.label)
    assert_equal "adressevaelger", suggestions.first.provider
  end

  def test_search_aliases_autocomplete
    http = lambda do |_uri, _request|
      ok_json("status" => "ok", "fund" => [])
    end

    assert_equal [], Adressevaelger::Client.new(http: http).search("Badevej")
  end

  def test_raises_provider_error_on_http_failure
    http = lambda do |_uri, _request|
      Net::HTTPBadRequest.new("1.1", "400", "Bad Request").tap do |response|
        response.define_singleton_method(:body) { "{}" }
      end
    end

    error = assert_raises(Adressevaelger::ProviderError) do
      Adressevaelger::Client.new(http: http).autocomplete("Badevej")
    end
    assert_match(/400/, error.message)
  end

  private

  def ok_json(payload)
    Net::HTTPOK.new("1.1", "200", "OK").tap do |response|
      response.define_singleton_method(:body) { JSON.generate(payload) }
    end
  end
end
