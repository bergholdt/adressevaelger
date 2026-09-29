# frozen_string_literal: true

module Adressevaelger
  PROVIDER = "adressevaelger"

  # Autocomplete / vask hit from Adressevælger or Adressevask.
  Suggestion = Data.define(:id, :type, :label, :provider) do
    def self.from_fund(fund)
      new(
        id: fund.fetch("id"),
        type: fund.fetch("type"),
        label: fund.fetch("titel"),
        provider: Adressevaelger::PROVIDER
      )
    end
  end
end
