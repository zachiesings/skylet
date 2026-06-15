# Skylet

A beautifully simple **weather app** that lives in your Mac's menu bar. See the
current temperature at a glance, with a full current-conditions card and a
multi-day forecast one click away — no browser, no clutter.

**Privacy first** — Skylet uses the free [Open-Meteo](https://open-meteo.com)
API. No account, no API key, no tracking. Only your chosen locations are stored,
and they stay on your Mac.

## Features
- Live temperature in your menu bar
- Current conditions: temperature, hi/lo, humidity & wind
- Location search powered by Open-Meteo geocoding
- **Skylet Pro** (one-time purchase): unlimited locations, full 7-day forecast,
  all themes, and auto-refresh

## Build
The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
open Skylet.xcodeproj
```

CI/CD: built & signed for the Mac App Store on Codemagic (`codemagic.yaml`).
Monetization via [RevenueCat](https://www.revenuecat.com) (entitlement `pro`).

- Bundle ID: `app.skylet.Skylet`
- Minimum macOS: 13.0
