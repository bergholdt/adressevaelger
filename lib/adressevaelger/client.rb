# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

require_relative "suggestion"
require_relative "resolved_address"

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

    # Resolve a husnummer or adresse by DAR id.
    def resolve(id:, type: "husnummer")
      path = case type.to_s
      when "adresse" then "/adresser/#{id}"
      else "/husnumre/#{id}"
      end

      payload = get_json(path)
      build_resolved(payload, type: type.to_s)
    end

    private

      attr_reader :http

      def build_resolved(payload, type:)
        data = nested_entity(payload)
        vejnavn = scalar(pick(data, "vejnavn")) || dig_hash(data, "vejstykke", "navn") || dig_hash(data, "navngivenvej", "vejnavn")
        husnr = scalar(pick(data, "husnr", "husnummertekst", "husnummer"))
        postal = scalar(pick(data, "postnr")) || dig_hash(data, "postnummer", "postnr") || dig_hash(data, "postnummer", "nr")
        city = scalar(pick(data, "postnrnavn", "bynavn")) || dig_hash(data, "postnummer", "navn")
        etage = scalar(pick(data, "etagebetegnelse", "etage"))
        doer = scalar(pick(data, "doerbetegnelse", "dør", "doer"))

        point = data["adgangspunkt"] || dig_hash(data, "adgangsadresse", "adgangspunkt") || data["position"]
        easting, northing = extract_etrs89(point)
        latitude, longitude = transform_etrs89(easting, northing)

        id = pick(data, "id", "id_lokalid")
        husnummer_id = pick(data, "husnummer_id", "adgangsadresseid") || (type == "husnummer" ? id : nil)
        adresse_id = type == "adresse" ? id : pick(data, "adresse_id")

        ResolvedAddress.new(
          line1: [vejnavn, husnr].compact.reject { |part| blank?(part) }.join(" "),
          line2: nil,
          postal_code: postal.to_s,
          city: city.to_s,
          country: "DK",
          etage: etage,
          doer: doer,
          address_provider: Adressevaelger::PROVIDER,
          external_address_id: adresse_id || husnummer_id,
          external_building_id: husnummer_id,
          latitude: latitude,
          longitude: longitude,
          coord_easting: easting,
          coord_northing: northing,
          coord_epsg: easting ? EPSG : nil
        )
      end

      def nested_entity(payload)
        %w[data husnummer adresse].each do |key|
          value = payload[key]
          return value if value.is_a?(Hash)
        end
        payload
      end

      def pick(hash, *keys)
        keys.each do |key|
          value = hash[key]
          return value if present?(value)
        end
        nil
      end

      def dig_hash(hash, *keys)
        return nil unless hash.is_a?(Hash)

        hash.dig(*keys)
      end

      def scalar(value)
        return nil if blank?(value) || value.is_a?(Hash) || value.is_a?(Array)

        value
      end

      def extract_etrs89(point)
        return [nil, nil] if blank?(point)

        if point.is_a?(Array) && point.size >= 2
          return [point[0].to_f, point[1].to_f]
        end

        coords = point["koordinater"] || point["coordinates"] || point["position"] || dig_hash(point, "geometri", "coordinates")
        if coords.is_a?(Array) && coords.size >= 2
          return [coords[0].to_f, coords[1].to_f]
        end
        if coords.is_a?(Hash)
          easting = coords["x"] || coords["øst"] || coords["oest"] || coords["easting"]
          northing = coords["y"] || coords["nord"] || coords["northing"]
          return [easting.to_f, northing.to_f] if present?(easting) && present?(northing)
        end

        easting = point["øst"] || point["oest"] || point["easting"] || point["x"]
        northing = point["nord"] || point["northing"] || point["y"]
        return [nil, nil] if blank?(easting) || blank?(northing)

        [easting.to_f, northing.to_f]
      end

      # Wired in a later commit when the optional PROJ helper is available.
      def transform_etrs89(_easting, _northing)
        [nil, nil]
      end

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
