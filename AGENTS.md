# Agent notes

Public README is for gem users. Keep maintainer checklists and rejected scope out of it.

## Security

CodeQL (`.github/workflows/codeql.yml`), Dependabot (`.github/dependabot.yml`), secret scanning, and security advisories (`.github/SECURITY.md`).

## Test

```sh
bundle exec rake test
bundle exec rake rubocop
# or: bundle exec rake
```

## VCR

Cassettes are recorded against the real Adressevælger API. Do not hand-write response bodies.

```sh
VCR_RECORD=all bundle exec rake test TEST=test/client_vcr_test.rb
```

CI uses `record: :none`. Query tokens are redacted on record.

## Release

1. Bump `Adressevaelger::VERSION` in `lib/adressevaelger/version.rb`.
2. Update `CHANGELOG.md`.
3. Tag `vX.Y.Z` matching that version and push the tag.

`.github/workflows/push_gem.yml` checks the tag and publishes with RubyGems Trusted Publishing.
