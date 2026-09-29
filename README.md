# Adressevaelger

Ruby client for Klimadatastyrelsen **Adressevælger** and **Adressevask**
(Danmarks Adresseregister / DAR). Denmark only — no multi-country router,
manual entry adapter, or commercial geocoder fallback.

## Install

```ruby
# Gemfile
gem "adressevaelger"

# Optional: fill ResolvedAddress#latitude / #longitude from ETRS89
gem "rgeo-proj4"
```

```sh
bundle add adressevaelger
# or: gem install adressevaelger
```

Requires Ruby 3.1+. No Rails dependency.

## Usage

```ruby
require "adressevaelger"

client = Adressevaelger::Client.new(
  token: ENV.fetch("ADRESSEVAELGER_TOKEN") # or rely on demo default locally
)

# Autocomplete / search (min 3 characters)
suggestions = client.autocomplete("Vestergade 1")
suggestions.first.id    # => DAR husnummer id
suggestions.first.label # => "Vestergade 1, 1456 København K"

# Resolve husnummer or adresse by id
resolved = client.resolve(id: suggestions.first.id, type: "husnummer")
resolved.line1          # => "Vestergade 1"
resolved.postal_code   # => "1456"
resolved.coord_easting  # => ETRS89/UTM32N
resolved.latitude       # => WGS84 if rgeo-proj4 is installed, else nil

# Adressevask (free-text wash)
washed = client.validate("vestergade 1 københavn")
# alias: client.vask(...)
```

Environment variables:

| Variable | Purpose |
| --- | --- |
| `ADRESSEVAELGER_TOKEN` | API token (preferred over the demo default) |
| `ADRESSEVAELGER_BASE_URL` | Override host (default `https://adressevaelger.dk`) |

## Optional ETRS89 → WGS84

`Adressevaelger::Etrs89ToWgs84` soft-requires [`rgeo-proj4`](https://github.com/rgeo/rgeo-proj4).
If PROJ is unavailable, `resolve` still returns ETRS89 easting/northing and leaves
WGS84 latitude/longitude `nil`.

```ruby
Adressevaelger::Etrs89ToWgs84.available? # => true/false
lat, lon = Adressevaelger::Etrs89ToWgs84.call(easting: 724_533.07, northing: 6_176_026.84)
```

## Token notes

The Adressevælger HTTP API requires a `token` query parameter. Until Brugerstyring
lands, Klimadatastyrelsen documents a shared demo token for exploration. The gem
falls back to that demo token when none is configured — **do not rely on it in
production**. Obtain a proper token via [Dataforsyningen](https://dataforsyningen.dk/).

## Testing

```sh
bundle exec rake test
```

HTTP integration tests use [VCR](https://github.com/vcr/vcr) cassettes recorded
against the real API (tokens redacted). CI uses `record: :none` (fail-closed).
To refresh cassettes locally:

```sh
VCR_RECORD=all bundle exec rake test TEST=test/client_vcr_test.rb
```

Never hand-write cassette response bodies.

## Scope

**In:** Adressevælger search/autocomplete, resolve by husnummer/adresse id,
Adressevask validate, optional PROJ transform.

**Out:** Multi-country routing, Manual adapters, commercial fallback geocoders,
Rails controllers/Stimulus, CRM persistence helpers.

## Attribution

Address data via [Dataforsyningen](https://dataforsyningen.dk/) /
Klimadatastyrelsen Adressevælger and Adressevask. This gem is an independent
open-source client and is not affiliated with or endorsed by Klimadatastyrelsen.

## Releasing

Version bumps are intentional — CI does not auto-bump on every `main` push.

1. Bump `Adressevaelger::VERSION` in `lib/adressevaelger/version.rb` (gemspec reads it).
2. Update `CHANGELOG.md` for that version.
3. Commit and push to `main`.
4. Tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`
   (or create a GitHub Release for `vX.Y.Z` — that also pushes the tag).
5. Tag **must** match the gem version (`v0.1.0` ↔ `0.1.0`). The
   [push_gem](.github/workflows/push_gem.yml) workflow verifies this, then
   publishes via [RubyGems Trusted Publishing](https://guides.rubygems.org/trusted-publishing/)
   (`rubygems/release-gem`, OIDC — no `RUBYGEMS_API_KEY` secret).

### One-time RubyGems Trusted Publisher setup

The gem is not on RubyGems yet, so use a **pending** trusted publisher
(Rasmus must click through the UI; no credentials belong in this repo):

1. Sign in at [rubygems.org](https://rubygems.org/) (MFA on).
2. Open [Pending trusted publishers](https://rubygems.org/profile/oidc/pending_trusted_publishers).
3. Click **Create**.
4. Fill in:
   - **Gem name:** `adressevaelger`
   - **Repository owner:** `bergholdt`
   - **Repository name:** `adressevaelger`
   - **Workflow filename:** `push_gem.yml`
   - **Environment name:** `release`
5. Click **Create Pending trusted publisher**.
6. In GitHub → repo **Settings → Environments**, create an environment named
   `release` (no required reviewers needed for a solo maintainer).

After the first successful tag-triggered publish, the pending publisher becomes
a normal trusted publisher and you own the gem on RubyGems.org.

## License

MIT. See [LICENSE.txt](LICENSE.txt).
