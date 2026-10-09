# Changelog

## 0.1.1

- Add RuboCop lint job and shared style config in CI. No public API changes.

## 0.1.0

- Initial public release: Adressevælger client (`autocomplete` / `search`),
  resolve by husnummer or adresse id, Adressevask `validate` / `vask`, and
  optional ETRS89→WGS84 via soft-required `rgeo-proj4`.
- VCR cassettes for husnummer search and resolve (tokens redacted).
