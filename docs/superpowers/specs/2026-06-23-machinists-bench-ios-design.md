# The Machinist's Bench — Native iOS (SwiftUI) Design

**Date:** 2026-06-23
**Status:** Approved (design); spec under review
**Source:** `app.html` — React single-file PWA "The Machinist's Bench" v4.32

## Goal

Port the existing web app (`app.html`) to a native SwiftUI iOS app. The web app is
a machinist reference tool: speeds/feeds calculators, thread/drill/fit reference
tables, and shop-math utilities, all client-side with no backend.

## Locked Decisions

- **Visual direction:** Faithful base + native polish. Keep the dark "shop terminal"
  identity (grid background, sticky header, per-section accent colors, bundled fonts),
  but adopt native iOS patterns where they're better (navigation, inputs, haptics,
  Dynamic Type, persisted settings).
- **Palette:** Catppuccin **Mocha**. The web's accent roles remap to Catppuccin
  accents: blue→blue, teal→teal, amber→peach, violet→mauve, green→green,
  orange→peach, red→red. Base `#1e1e2e`, text `#cdd6f4`, plus surface/overlay tones.
- **Diagrams:** Deferred. The web app's many interactive SVG diagrams (drill point,
  micrometer demo, dovetail, boring-head dial, thread forms, etc.) are NOT in the
  initial scope. Calculators and reference tables first; diagrams added later, only
  if wanted, as SwiftUI `Canvas`.
- **Scope strategy:** Vertical slice first (shell + theme + units + shared components
  + Turning), then fan out one section at a time.
- **Target:** iPhone, iOS 17+, Swift 6. Distribution: personal / TestFlight (no App
  Store review). Signing team set in Xcode.

## Architecture

Pure-Swift SwiftUI app, **zero third-party dependencies**. The web app is already the
ideal shape: no backend, all data is constant tables, all calculators are pure
functions. Port the math verbatim; rebuild the UI natively.

No heavy architecture — calculators are pure functions, views hold their own
`@State`, Imperial/Metric is one shared setting via `@AppStorage` exposed through the
environment. No view-model layer, no Redux; that would be ceremony for stateless math.

## Project Layout

```
MachinistsBench/
  App.swift              // @main, home screen + NavigationStack
  Theme/
    Catppuccin.swift     // Mocha palette + per-section accent roles
    Typography.swift     // font roles (display / body / mono)
  Core/
    Units.swift          // imperial/metric enum + conversions (web's mmin/cc/etc),
                         // @AppStorage-backed, environment-injected
    Data/                // ported constant tables: MAT, drills (WIRE/LETTER/FRAC),
                         // UNC/UNF/METRIC threads, fits, CTE, hardness…
    Calc/                // pure calc funcs per operation
  Components/            // Panel, Field, NumberInput, Segmented, Readout, Note,
                         // DataTable, Collapse, SpeedInput
  Sections/
    Turning/             // slice 1; other 14 sections added incrementally
  Resources/
    Fonts/               // JetBrains Mono + Chakra Petch (OFL, same as web)
```

## Shared Components (1:1 from web primitives)

| Native | Web source | Purpose |
|--------|-----------|---------|
| `Panel` | `Panel` | Titled card with accent, optional subtitle/right slot |
| `Field` | `Field` | Label + hint wrapper around an input |
| `NumberInput` | `NumIn` | Numeric entry, step/min, accent |
| `Segmented` / `Picker` | `Seg` / `Sel` | Segmented control / dropdown |
| `Readout` | `Readout` / `ReadOnly` | Result display (label/value/unit/sub) |
| `Note` | `Note` | info / warn / bad / good callout |
| `DataTable` | `Table` | Columns + rows, optional row tap |
| `Collapse` | `Collapse` | Collapsible section |
| `SpeedInput` | `SpeedIn` | SFM ↔ m/min aware speed entry with range hint |

Building these once is what makes every later section cheap.

## Navigation (primary native-polish win)

The web crams 15 sections into a collapsible tab strip. Natively this becomes a
**grouped home screen** with three groups — Cutting / Calculate & Measure / Reference
— and tapping a section pushes its calculator via `NavigationStack`. Imperial/Metric
is a toolbar toggle persisted with `@AppStorage`. Each section's Catppuccin accent
carries through its header, preserving the web's color-coding.

Section groups (15 total):

- **Cutting:** Turning, Drilling, Milling, Tapping, Threading, Boring, Reaming, Band Saw
- **Calculate & Measure:** Shop Math, Converter, Layout, Scale
- **Reference:** Threads, Rose Engine, Reference

## Theme

Catppuccin Mocha base with the accent remapping above. Keep the grid background and
sticky/large-title header identity. Bundle JetBrains Mono + Chakra Petch (OFL, the
same fonts the web app loads) so it reads as the same product; fall back to SF
Mono / SF Pro if a font fails to load.

## Data & Correctness (the crown jewels)

The constant tables (`MAT`, drill size tables `WIRE`/`LETTER`/`FRAC`, thread series
UNC/UNF/METRIC, `CTE`, fits, hardness conversion) port **verbatim** from the JS —
these are the app's value and must match the web exactly. Calculation functions
(RPM, IPM, MRR, cutting HP, tap drill, nearest drill, coating/lube factors) port
verbatim too, preserving the web's formulas and rounding.

## Error Handling

Empty or invalid numeric input → blank readout, never a crash (mirrors the web's
parse-float-or-blank behavior). Out-of-range cutting speeds show a warning `Note`
(the web's `inRange` logic). No persistence beyond the Imperial/Metric preference.

## Testing

Lazy-but-covered: a handful of XCTest golden-value assertions per calculator, with
expected values captured from the live web app (RPM, IPM, MRR, tap drill, nearest
drill, etc.). These are the regression net for the verbatim math port. No UI tests,
no per-component suites.

## Prerequisites (environment)

- `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` — **done.**
  Xcode 16.1 now active.
- `xcodebuild -downloadPlatform iOS` — **pending.** No iOS simulator runtime is
  installed yet (~7GB, no sudo). Required before running the Milestone 1 slice in the
  simulator.
- A signing team configured in Xcode for on-device / TestFlight builds.

## Milestones

1. **Vertical slice** — Xcode project + Catppuccin theme + Units + shared component
   library + **Turning** section fully working in the simulator. Proves the pattern
   end-to-end.
2. **Fan out cutting calcs** — Drilling, Milling, Tapping, Threading, Boring,
   Reaming, Band Saw.
3. **Calculate & measure** — Shop Math, Converter, Layout, Scale.
4. **Reference** — Threads finder, Reference tables, Rose Engine.
5. **Diagrams (deferred)** — rebuild SVG diagrams as SwiftUI `Canvas`, section by
   section, only if wanted.

## Out of Scope (initial)

- Interactive SVG diagrams (deferred to Milestone 5).
- App Store release, iPad/universal layout, macOS.
- Offline service-worker concerns (native app is inherently offline).
- Any backend, accounts, sync, or analytics.
