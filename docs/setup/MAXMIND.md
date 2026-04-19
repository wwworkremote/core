# MaxMind GeoIP2 Setup Task

This document outlines the steps required to configure local geocoding using MaxMind.

## 1. Credentials
You need a license key from your MaxMind account.

## 2. Configuration
Add the license key to your local encrypted credentials:

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Add the following structure:
```yaml
geoip:
  license_key: "YOUR_LICENSE_KEY"
```

## 3. Database Download
Run the provided maintenance task to download and update the MaxMind database:

```bash
bin/update-geoip
```

## 4. Environment
Ensure the environment uses the configured key:
- The `GeoipClient` (in `app/services/geo/geoip_client.rb`) is designed to pull this key from `Rails.application.credentials.dig(:geoip, :license_key)`.
- The database is stored locally in `data/maxmind/GeoLite2-City.mmdb`.

## 5. Enable Geocoding
Once the setup is verified, re-enable geocoding in `config/initializers/ahoy.rb`:
```ruby
Ahoy.geocode = true
```
