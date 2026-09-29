# frozen_string_literal: true

module Adressevaelger
  Error = Class.new(StandardError)
  # Raised when the Adressevælger HTTP API fails, returns invalid JSON, or is unreachable.
  ProviderError = Class.new(Error)
end
