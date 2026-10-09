# frozen_string_literal: true

module Adressevaelger
  class Error < StandardError
  end

  # Raised when the Adressevælger HTTP API fails, returns invalid JSON, or is unreachable.
  class ProviderError < Error
  end
end
