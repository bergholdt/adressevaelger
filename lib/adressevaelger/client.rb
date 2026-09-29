# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

require_relative "suggestion"

module Adressevaelger
  # HTTP client for Klimadatastyrelsen Adressevælger (+ Adressevask).
  #
  # Official host is adressevaelger.dk (api.adressevaelger.dk does not resolve).
  class Client
    # Token is required by the API. Until Brugerstyring lands, KDS recommends
    # this shared demo token for exploration — replace it in production.
    DEFAULT_TOKEN = "adressevaelger123"
    DEFAULT_BASE_URL = "https://adressevaelger.dk"
    EPSG = 25832

    attr_reader :base_url, :token

    def initialize(token: nil, base_url: nil, http: nil)
      @token = present_string(token) || present_string(ENV["ADRESSEVAELGER_TOKEN"]) || DEFAULT_TOKEN
      @base_url = present_string(base_url) || present_string(ENV["ADRESSEVAELGER_BASE_URL"]) || DEFAULT_BASE_URL
      @http = http
    end

    # Autocomplete husnumre by free-text query (min 3 characters).
    def autocomplete(query)
      return [] if blank?(query) || query.to_s.length < 3

      payload = get_json("/husnumre/soeg", tekst: query)
      Array(payload["fund"]).filter_map do |fund|
        next unless present?(fund["id"]) && present?(fund["titel"])

        Suggestion.from_fund(fund)
      end
    end

    # Alias used by callers that think in "search" terms.
    alias search autocomplete

    private

      attr_reader :http

      def get_json(path, params = {})
        uri = URI.join("#{base_url}/", path.delete_prefix("/"))
        query = params.merge(token: token).compact
        uri.query = URI.encode_www_form(query)

        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        request["User-Agent"] = "Adressevaelger/#{VERSION}"

        response = perform(uri, request)
        unless response.is_a?(Net::HTTPSuccess)
          raise ProviderError, "Adressevælger error (#{response.code})"
        end

        JSON.parse(response.body)
      rescue JSON::ParserError
        raise ProviderError, "Adressevælger returned invalid JSON"
      end

      def perform(uri, request)
        if http
          return http.call(uri, request)
        end

        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |client|
          client.request(request)
        end
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError, Socket::ResolutionError => e
        raise ProviderError, "Adressevælger unreachable (#{e.class})"
      end

      def blank?(value)
        value.nil? || (value.respond_to?(:empty?) && value.empty?) ||
          (value.is_a?(String) && value.strip.empty?)
      end

      def present?(value)
        !blank?(value)
      end

      def present_string(value)
        return nil if blank?(value)

        value.to_s
      end
  end
end
