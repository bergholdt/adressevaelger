# frozen_string_literal: true

# VCR for Adressevælger HTTP.
#
# Rules:
# - Cassettes MUST be recorded against the real HTTP API. Never hand-write them.
# - Local record / refresh: `VCR_RECORD=all bundle exec rake test`
# - Local default without VCR_RECORD: `record: :once` (network only if cassette missing).
# - CI: `record: :none` — replay only; unhandled HTTP / missing cassette fails closed.
# - Do NOT set allow_http_connections_when_no_cassette.
# - Secrets are redacted on record (query tokens).
require "vcr"
require "webmock"

module VcrRecordMode
  module_function

  def call
    if ENV["VCR_RECORD"] && !ENV["VCR_RECORD"].empty?
      ENV["VCR_RECORD"].to_sym
    elsif ENV["CI"] && !ENV["CI"].empty?
      :none
    else
      :once
    end
  end
end

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path("../cassettes", __dir__)
  config.hook_into :webmock
  config.ignore_localhost = true
  config.default_cassette_options = {
    record: VcrRecordMode.call,
    match_requests_on: [:method, VCR.request_matchers.uri_without_param(:token)]
  }

  config.filter_sensitive_data("<ADRESSEVAELGER_TOKEN>") { ENV["ADRESSEVAELGER_TOKEN"] if ENV["ADRESSEVAELGER_TOKEN"] && !ENV["ADRESSEVAELGER_TOKEN"].empty? }
  config.filter_sensitive_data("<ADRESSEVAELGER_TOKEN>") { Adressevaelger::Client::DEFAULT_TOKEN }

  config.before_record do |interaction|
    scrub = lambda do |headers|
      next unless headers

      headers.keys.select { |k| k.to_s.match?(/\A(Authorization|Cookie|Set-Cookie)\z/i) }.each { |k| headers.delete(k) }
    end

    scrub.call(interaction.request.headers)
    scrub.call(interaction.response.headers)
  end
end
