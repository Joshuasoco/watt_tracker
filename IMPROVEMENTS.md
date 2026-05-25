# WattWise — Improvement Plan
> Generated: 2026-05-24 | Status: Draft

---

## Overview

This document tracks all identified hardcoded/mock data in WattWise and provides a concrete, phased plan to replace them with real, dynamic sources. Each finding includes the affected file, what is hardcoded, and the recommended fix.

---

## Table of Contents

1. [Goals](#goals)
2. [Findings by File](#findings-by-file)
3. [Phased Improvement Plan](#phased-improvement-plan)
4. [Quick Wins](#quick-wins)
5. [Out of Scope](#out-of-scope)

---

## Goals

| # | Goal |
|---|------|
| 1 | Replace static wattage presets with dynamic, device-specific data |
| 2 | Replace fixed heuristics with telemetry and calibrated models |
| 3 | Eliminate placeholder defaults by tracking `unknown` vs `confirmed` values |
| 4 | Store data provenance and confidence per component and calculation |

---

## Findings by File

> **Legend:** 🔴 High impact · 🟡 Medium impact · 🟢 Low impact

---

### 🔴 `lib/data/presets/wattage_presets.dart`

**Hardcoded:** Device and component wattage presets (e.g. laptop = 65W, GPU midrange = 180W).

**Fix:** Load presets from a versioned local JSON file that can be updated OTA. Allow user edits and merge with scan results and saved overrides.

---

### 🔴 `lib/data/repositories/wattage_repository.dart`

**Hardcoded:** Seeding uses the static presets list directly.

**Fix:** Seed from a versioned preset store (local JSON or remote update). Track preset version in Hive to support refresh and migration.

---

### 🔴 `lib/data/repositories/wattage_preset_repository.dart`

**Hardcoded:** CPU and GPU watt maps plus fixed fallbacks (CPU = 65W, integrated GPU = 15W, dedicated GPU = 150W).

**Fix:** Enrich scan with hardware IDs and look up against a local hardware DB. Support telemetry-driven overrides using measured power. Cache resolved TDP per device.

---

### 🔴 `lib/data/services/system_scan_service.dart`

**Hardcoded:** Fallback RAM (8GB), storage (1 SSD), fan/RGB defaults by chassis, storage type heuristics, GPU integrated check based on AdapterRAM < 2GB or name contains "Intel"/"Vega".

**Fix:** Use CIM classes (`Win32_Processor`, `Win32_PhysicalMemory`, `MSFT_PhysicalDisk`, `MSFT_StorageFaultDomain`) for exact media types. Query fan count and RGB status via vendor APIs or OpenRGB. Store scan confidence and prompt user for missing fields.

---

### 🔴 `lib/data/services/power_estimation_service.dart`

**Hardcoded:** Load fractions, multipliers, idle fractions, clamp bounds, and confidence thresholds.

**Fix:** Compute multipliers from actual telemetry (CPU/GPU utilization, package power) and user profile history. Support calibration curves per device. Store model version and allow recalculation when inputs change.

---

### 🔴 `lib/features/dashboard/cubit/live_timer_cubit.dart`

**Hardcoded:** Storage watts fixed to 7W/3W; RGB watts fixed to 10W; CPU/GPU watts resolved only by presets.

**Fix:** Use per-device overrides from scan and user confirmation. Refine watts during active sessions via telemetry. Store per-component calibration.

---

### 🟡 `lib/data/models/system_spec_model.dart`

**Hardcoded:** Defaults for CPU/GPU names, wattage, storage watts, fan count, motherboard watts.

**Fix:** Add an `unknown` state per field and persist a `source` tag (`scan`, `user`, `inferred`). Show defaults only as UI placeholders, never as real data.

---

### 🟡 `lib/data/services/energy_audit_service.dart`

**Hardcoded:** Rule thresholds (e.g. `dailyHours >= 6`, `GPU idle watts = max(18, 0.18 × GPUwatts)`), tip savings assumptions (GPU 15%, fan 30%), placeholder finding ID.

**Fix:** Derive thresholds from rolling telemetry and historical sessions. Store configurable thresholds in audit settings. Compute savings using measured idle and active windows. Remove placeholder ID and return a dedicated "no findings" state.

---

### 🟡 `lib/data/services/cpu_load_poller_service.dart`

**Hardcoded:** Idle watts as 10%–15% of TDP with linear scaling.

**Fix:** Use package power telemetry (HWiNFO shared memory, OpenHardwareMonitor, or Windows Energy Estimation Engine) when available. Learn idle watts from observed floor over time.

---

### 🟡 `lib/data/services/windows_activity_sampler.dart`

**Hardcoded:** Default sample window of 5 seconds; returns `0` on errors.

**Fix:** Make sample duration configurable. On counter unavailability, emit `unknown` and surface reduced confidence instead of `0`. Use GPU-specific counters scoped to the active adapter.

---

### 🟡 `lib/data/repositories/energy_audit_repository.dart`

**Hardcoded:** Audit defaults (auto-enabled, 14-day interval, 7-day snooze).

**Fix:** Store defaults in a versioned settings object. Initialize from a settings schema. Allow user overrides and support migrations.

---

### 🟡 `lib/features/settings/view/settings_page.dart`

**Hardcoded:** Same fixed storage and RGB watts in `_resolvedSpec`.

**Fix:** Rely on the shared resolution pipeline (scan → overrides → telemetry) used by the estimator. Show per-component confidence in the UI.

---

### 🟡 `lib/features/settings/cubit/settings_state.dart`

**Hardcoded:** Default currency code `PHP` and default rate `12`.

**Fix:** Initialize from `AppPreferencesRepository` after it applies locale-aware defaults. Keep state `null` until loaded.

---

### 🟢 `lib/data/repositories/app_preferences_repository.dart`

**Hardcoded:** Default currency code `PHP` and default rate `12.0`.

**Fix:** Initialize from device locale and allow provider-specific presets. Mark as `unset` until confirmed during onboarding.

---

### 🟢 `lib/data/repositories/wattwise_prefs_repository.dart`

**Hardcoded:** Default rate `12.0`, daily hours `8.0`, milestone hours `2.0`, currency symbol fallback.

**Fix:** Split `unset` vs `confirmed` values and require onboarding confirmation. Use system locale only as a first-run suggestion.

---

### 🟢 `lib/features/dashboard/cubit/live_timer_state.dart`

**Hardcoded:** Initial currency symbol, rate, daily hours, and spec defaults.

**Fix:** Introduce a loading state that defers cost computation until prefs are loaded. Show placeholders in UI without treating them as real values.

---

### 🟢 `lib/features/calculator/view/calculator_page.dart`

**Hardcoded:** Uses device presets and selects the first preset by default.

**Fix:** Default to scanned or user-defined devices. Fall back to an explicit "Unknown device" option that requires confirmation before use.

---

### 🟢 `lib/data/services/tray_service.dart`

**Hardcoded:** Default tooltip shows `PHP 0.00`.

**Fix:** Use the saved currency symbol or hide cost until a session is active. Store last known formatted cost per user.

---

### 🟢 `lib/features/audit/cubit/energy_audit_cubit.dart`

**Hardcoded:** Default snooze duration is 7 days.

**Fix:** Read default snooze days from audit settings. Allow user to change this in Settings.

---

## Phased Improvement Plan

### Phase 1 — Data Provenance & UX Safety *(1–2 weeks)*

The goal of this phase is to make the app honest about what it knows and doesn't know, without breaking existing functionality.

- Add per-field metadata: `source` (`scan` | `user` | `inferred`), `confidence` (0.0–1.0), `lastUpdated`.
- Change UI to treat `unknown` values as unknown, not as defaults.
- Store settings defaults in a versioned schema and migrate existing data.
- Remove placeholder finding ID in audit; return a proper "no findings" state.
- Move currency and rate defaults to locale-aware initial suggestions only.

**Deliverables:** `FieldMetadata` model, updated `system_spec_model.dart`, settings schema v2, migration script.

---

### Phase 2 — Dynamic Data Sources *(2–4 weeks)*

Replace the most impactful hardcoded values with real system data.

- Extend scan pipeline with CIM APIs (`MSFT_PhysicalDisk`, `Win32_PhysicalMemory`) for exact media type and capacity.
- Add optional telemetry sources for CPU/GPU package power (OpenHardwareMonitor, HWiNFO shared memory, or Windows Energy APIs).
- Add USB/HID enumeration for peripheral detection with estimated wattages by device type.
- Load wattage presets from a versioned local JSON file with an OTA update path.

**Deliverables:** Updated `system_scan_service.dart`, telemetry adapter interface, `wattage_presets.json`.

---

### Phase 3 — Calibration & Learning *(4–6 weeks)*

Make WattWise smarter the longer it runs.

- Support user-provided meter readings to compute a calibration factor per device.
- Learn idle and load watt profiles from session history.
- Replace fixed audit thresholds with rolling baselines and configurable rules stored in audit settings.
- Support re-calculation of historical sessions when calibration changes.

**Deliverables:** Calibration model, rolling baseline engine, configurable audit rules schema.

---

## Quick Wins

These can be done independently at any time with low risk:

- [ ] Remove placeholder finding ID in `energy_audit_service.dart` → use a `NoFindings` state.
- [ ] Add an "unknown" badge to component rows in the UI where defaults are in use.
- [ ] Move currency and rate initialization to locale-aware suggestions only.
- [ ] Make snooze duration configurable from Settings instead of hardcoded.
- [ ] Hide tray tooltip cost until a session is active.

---

## Out of Scope

The following areas were reviewed but require no changes:

- `build/` — generated code, no actionable mock data.
- `third_party/` — vendor code, not owned by this project.
- `test/` — intentional fakes for testing; keep as-is.