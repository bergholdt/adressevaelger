# frozen_string_literal: true

require_relative "adressevaelger/version"
require_relative "adressevaelger/error"
require_relative "adressevaelger/suggestion"
require_relative "adressevaelger/resolved_address"
require_relative "adressevaelger/etrs89_to_wgs84"
require_relative "adressevaelger/client"

# Ruby client for Klimadatastyrelsen Adressevælger + Adressevask (DAR).
#
# Denmark only. Country routing, manual entry, and commercial geocoders belong
# in the host application.
module Adressevaelger
end
