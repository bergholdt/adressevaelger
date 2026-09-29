# frozen_string_literal: true

module Adressevaelger
  # Autocomplete / vask hit from Adressevælger or Adressevask.
  Suggestion = Data.define(:id, :type, :label, :provider) do
    PROVIDER = "adressevaelger"

    def self.from_fund(fund)
      new(
        id: fund.fetch("id"),
        type: fund.fetch("type"),
        label: fund.fetch("titel"),
        provider: PROVIDER
      )
    end
  end
end
