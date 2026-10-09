# frozen_string_literal: true

# VCR for Adressevælger HTTP. Record against the real API; never hand-write cassettes.
# Local refresh: VCR_RECORD=all. CI uses record: :none. Query tokens are redacted.
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

  config.filter_sensitive_data("<ADRESSEVAELGER_TOKEN>") do
    ENV["ADRESSEVAELGER_TOKEN"] if ENV["ADRESSEVAELGER_TOKEN"] && !ENV["ADRESSEVAELGER_TOKEN"].empty?
  end
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
