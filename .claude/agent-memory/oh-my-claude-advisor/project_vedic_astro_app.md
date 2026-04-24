---
name: Vedic Astrology App - Project Context
description: Greenfield Swift app (macOS + iOS) for Vedic astrology with JHora-class precision, using Swiss Ephemeris C bridging
type: project
---

Greenfield Vedic astrology app targeting macOS + iOS with calculation-first approach and JSON/Markdown export for Claude interpretation.

**Why:** User wants JHora-class precision in a native Swift app with P2P sync (no cloud).

**How to apply:**
- Swiss Ephemeris C library is the core dependency -- AGPL license decision is blocking
- Thread safety of SwissEph global state (swe_set_sid_mode, swe_set_ephe_path) requires serial dispatch queue architecture
- Sunrise/sunset via swe_rise_trans() is infrastructure, not a feature -- many downstream systems depend on it
- Existing archived Swift wrapper exists (vsmithers1087/SwissEphemeris) as potential starting point
- Scope risk is high: stated v1 includes ALL divisional charts, ALL dasha systems, full Shadbala, Ashtakavarga -- recommend phased vertical slices
- Contested calculations (D30 Parashari vs Greek, Chara Dasha Rao vs Rath) need explicit tradition parameters
