# Improving WattWise

This document outlines what I would implement as a senior developer to improve WattWise in terms of accuracy, reliability, performance, UX, and product growth.

## 1) Priority Order (What to do first)

1. Improve estimate accuracy and transparency.
2. Stabilize Windows hardware scanning and fallback behavior.
3. Add data model versioning and migration safety in Hive.
4. Add proper test coverage for estimation math and onboarding flow.
5. Improve dashboard insights (cost trends, savings opportunities).
6. Add background resilience (tray behavior, restart safety, notifications).

## 2) Accuracy and Trust (Most important)

### A. Calibrated Power Profiles
- Create a tiered estimation model:
  - `Base idle power` by hardware class.
  - `Dynamic load multiplier` for CPU/GPU usage scenarios.
  - `Peripheral overhead` (fans, RGB, storage activity).
- Let users choose usage profile presets:
  - `Idle/Office`, `Gaming`, `Render/AI`, `Balanced`.
- Add optional manual calibration:
  - User enters real watt reading from a smart plug or UPS.
  - Use a correction factor to personalize future estimates.
 
### B. Confidence Indicator
- Show an estimate confidence level: `High`, `Medium`, `Low`.
- Explain why confidence is lower (missing GPU model, unknown motherboard class, etc.).
- Provide one-click actions to improve confidence (confirm component, set usage profile).

### C. Explainability UI
- Add a "How this is calculated" panel:
  - Component breakdown in watts.
  - Formula for cost calculation.
  - Last updated timestamp.

## 3) Hardware Scan and Detection Robustness

### A. Scanner Pipeline
- Build scanner stages with explicit states:
  - `discover -> normalize -> enrich -> validate -> persist`.
- Cache successful scan outputs and keep previous known-good profile.
- If a scan step fails, degrade gracefully and continue with available data.

### B. Multi-source Detection Strategy (Windows)
- Primary source: PowerShell / WMIC replacements (CIM/WMI modern cmdlets).
- Secondary source: registry/device queries.
- Tertiary source: user confirmation prompts.
- Attach a source tag to each detected component (`auto_primary`, `auto_secondary`, `manual`).

### C. Unknown Component Strategy
- Add a deterministic fallback table by category and generation.
- Mark unknown values in UI and ask user for quick confirmation.

## 4) Data and Storage Safety

### A. Hive Schema Versioning
- Add explicit schema version in persisted user profile/settings boxes.
- Implement migrations for each version bump.
- Keep migration logs for diagnostics.

### B. Corruption/Recovery Path
- Detect unreadable Hive boxes and auto-backup before repair.
- Recover partial data when possible.
- Show non-technical error messages with retry action.

### C. Event Logging (Local)
- Add structured local logs for:
  - Scan results and errors.
  - Session start/stop.
  - Notification dispatch.
- Use rolling file logs to avoid unlimited growth.

## 5) Performance Optimizations

### A. UI Update Strategy
- Ensure session ticker updates only minimal widgets.
- Use throttled timers for expensive calculations.
- Debounce settings writes (electricity rate, usage hours).

### B. Background Work Isolation
- Move heavy parsing/normalization to isolate/background compute.
- Keep UI thread free during hardware enrichment.

### C. Startup Speed
- Use lazy initialization for non-critical services.
- Defer optional scan enrichment until dashboard is visible.

## 6) Product Features to Add

### A. Cost Intelligence
- Weekly/monthly trend charts.
- Baseline vs current cost comparison.
- Projected yearly cost at current behavior.

### B. Optimization Suggestions Engine
- Suggest actions with impact estimates:
  - Reduce daily usage by 1 hour.
  - Limit turbo mode during office tasks.
  - Enable balanced power plan.
- Show estimated monthly savings for each suggestion.

### C. Tariff and Time-of-Use Support
- Support multiple tariff periods (peak/off-peak).
- Optional weekend/weekday rates.
- Country/region template presets.

### D. Session Goals and Alerts
- Set daily/weekly budget caps.
- Notify when crossing thresholds (50%, 80%, 100%).

## 7) UX Improvements (Professional desktop flow)

### A. Onboarding as a Clear Journey
- Keep onboarding in small stages with progress:
  1. Hardware detection
  2. Hardware confirmation
  3. Rate setup
  4. Usage pattern
  5. Summary and start tracking
- Add a final pre-start review screen to reduce misconfiguration.

### B. Dashboard Hierarchy
- Top row: live watt estimate, session cost, monthly projection.
- Middle: component contribution breakdown.
- Bottom: trends + recommendations.

### C. Settings Quality
- Add "last scan time", "scan again", and "reset calibration" actions.
- Add import/export for profile and settings JSON.

## 8) Engineering Quality and Testing

### A. Unit Tests
- Estimation engine formulas.
- Tariff calculations.
- Migration and serialization logic.

### B. Widget/Integration Tests
- Onboarding happy path + failure path.
- Returning user route behavior.
- Live ticker and milestone notification triggers.

### C. CI Quality Gate
- Run: format, analyze, unit tests, key widget tests.
- Block merge when estimation tests fail.

## 9) Architecture Upgrades

### A. Domain Separation
- Keep clean boundaries:
  - `scan domain`
  - `estimation domain`
  - `session tracking domain`
  - `billing/tariff domain`
- Move formulas into pure Dart domain services for testability.

### B. Repository Interfaces
- Define repositories with interfaces for easier mock/testing.
- Keep Windows command execution in dedicated infrastructure adapters.

### C. Feature Flags
- Add simple local feature flags for experimental modules (e.g., advanced calibration).

## 10) Security and Privacy

- Keep everything local by default.
- Clearly document what is collected (hardware metadata only).
- Add a one-click "Delete local data" action.

## 11) Suggested 6-Week Delivery Plan

### Week 1-2 (Foundation)
- Scanner state pipeline + fallback handling.
- Hive versioning and migration scaffolding.
- Estimation engine refactor to pure services.

### Week 3-4 (Accuracy + UX)
- Calibration factor and confidence indicator.
- Onboarding step refinements and summary screen.
- Explainability panel for cost calculations.

### Week 5 (Insights)
- Trend charts and recommendations engine v1.
- Budget threshold notifications.

### Week 6 (Hardening)
- Test coverage expansion.
- Performance profiling and UI optimization.
- Bug bash and release checklist.

## 12) Success Metrics

Track these metrics after implementation:
- Estimation trust score (user-reported confidence).
- Onboarding completion rate.
- Time to first successful scan.
- Crash-free sessions.
- Average session duration in tray mode.
- Percentage of users applying optimization suggestions.

---

If I were implementing immediately, I would start with: (1) estimation confidence + explainability, (2) scanner fallback robustness, and (3) migration-safe persistence. These three improvements raise trust and stability the fastest.
