# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "minitest", "~> 5.25"
gem "rake", "~> 13.0"
gem "vcr", "~> 6.3"
gem "webmock", "~> 3.25"

# Optional coordinate transform (install for ETRS89 → WGS84).
# Listed here so the gem's own PROJ tests can run when PROJ is available.
gem "rgeo-proj4", "~> 5.0", require: false
