# frozen_string_literal: true

require_relative "lib/adressevaelger/version"

Gem::Specification.new do |spec|
  spec.name = "adressevaelger"
  spec.version = Adressevaelger::VERSION
  spec.authors = ["Rasmus Bergholdt"]
  spec.email = ["rasmus.bergholdt@gmail.com"]

  spec.summary = "Ruby client for Klimadatastyrelsen Adressevælger and Adressevask (DAR)."
  spec.description = <<~DESC
    HTTP client for the Danish Adressevælger autocomplete/search and Adressevask
    address-wash APIs (Danmarks Adresseregister / DAR), with an optional
    ETRS89/UTM32N → WGS84 helper via PROJ.
  DESC
  spec.homepage = "https://github.com/bergholdt/adressevaelger"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bergholdt/adressevaelger"
  spec.metadata["changelog_uri"] = "https://github.com/bergholdt/adressevaelger/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.start_with?(*%w[bin/ test/ .git .github Gemfile Rakefile])
    end
  end
  spec.require_paths = ["lib"]
end
