# Smart Energy Audit Feature Spec

## Goal

Smart Energy Audit helps WattWise move from passive tracking to active optimization.

Instead of only telling users what their PC costs, the audit explains:

- which components contribute most to the bill
- which parts of the hardware profile look wasteful for the user's usage pattern
- what changes are likely to reduce monthly cost
- how much money each recommendation could save

The feature should be implementation-ready for the current Windows desktop app, fit the existing Hive-backed local-first architecture, and work even when telemetry is partial.

## Scope

Phase 1 should support:

- profile-based energy audits using the saved hardware profile
- optional live-session-aware heuristics
- per-component cost attribution
- recommendation generation with estimated monthly savings
- audit history storage
- snooze and dismiss behavior for tips

Phase 1 should not require:

- cloud sync
- real wattmeter integration
- external benchmarking services
- per-process GPU tracing

Those can be added later without breaking the schema below.

## User Stories

### Home users

- As a casual PC owner, I want WattWise to explain which hardware parts cost the most so I can understand my electricity bill.
- As a laptop user, I want to know if I am leaving expensive features active when I do light work so I can stretch battery and lower energy use.

### Gamers

- As a gamer, I want to know when my GPU is costing me money outside gaming sessions so I can reduce waste.
- As a gamer, I want specific suggestions like frame caps, undervolting, or power limits with estimated savings so I can decide if the tweak is worth it.

### Remote workers and freelancers

- As a remote worker, I want WattWise to flag always-on accessories and long idle sessions so I can reduce recurring monthly cost.
- As a freelancer, I want a clear component-level breakdown so I can justify expense decisions and understand where cost is coming from.

### Power users

- As a builder with multiple fans, RGB, and peripherals, I want WattWise to identify non-essential draw so I can tune my rig.
- As an advanced user, I want to override assumptions and rerun the audit so the results match my actual setup.

## Entry Points

The audit can be triggered from:

- dashboard secondary action: `Run energy audit`
- settings page: `Run audit again`
- onboarding completion card: `See optimization tips`
- automatic suggestion banner after `N` tracked hours if no audit exists yet

Recommended rule:

- Show a lightweight prompt after 4 tracked hours or after onboarding if total estimated draw is above 180 W.

## Audit Inputs

The audit engine should read:

- saved `SystemSpecModel`
- saved electricity rate
- saved currency symbol
- saved daily usage hours
- optional session milestone hours
- optional recent live session totals and durations
- optional user overrides for component wattage or device presence

Future-friendly optional inputs:

- AC vs battery state
- chassis role from Windows power APIs
- active display count
- connected USB/HID/audio devices
- sampled GPU/CPU utilization

## Audit Logic

### Core principle

The audit should be deterministic and explainable.

Every finding must come from:

1. saved hardware data
2. optional Windows signals
3. rules with visible thresholds

Do not use opaque scores without an explanation.

### Audit stages

#### 1. Normalize the hardware profile

Build an `AuditedHardwareProfile` from the saved spec:

- CPU watts from preset repository or override
- GPU watts from preset repository or override
- RAM watts = `ramSticks * ramWattsPerStick`
- storage watts = `storageCount * storageWattsEach`
- fans watts = `fanCount * fansWattsEach`
- RGB watts = `rgbWatts` when enabled, else `0`
- motherboard/platform watts = `motherboardWatts`
- peripheral watts = sum of detected or user-added peripherals

#### 2. Compute baseline operating cost

Use existing WattWise assumptions:

- `hourlyCost = (totalWatts / 1000) * ratePerKwh`
- `dailyCost = hourlyCost * dailyHours`
- `monthlyCost = dailyCost * 30`

#### 3. Attribute cost to components

For each component bucket:

- `componentPercentOfDraw = componentWatts / totalWatts`
- `componentMonthlyCost = monthlyCost * componentPercentOfDraw`

This gives a percentage of the estimated monthly bill attributable to each part.

#### 4. Detect waste patterns

Findings are rule-based and severity-ranked.

Recommended buckets:

- `high_draw_core`
- `idle_waste`
- `always_on_extras`
- `profile_mismatch`
- `low_confidence`

### Waste detection rules

#### GPU idle waste

Trigger when all are true:

- GPU type is `dedicated`
- daily usage hours >= 6
- audit mode is not explicitly `gaming_only`
- either:
  - no GPU telemetry is available, so assume a default idle draw fraction
  - or sampled GPU utilization stays under a low threshold during audit sampling

Default assumption if no telemetry:

- dedicated GPU idle draw = `max(18 W, gpuWatts * 0.18)`

If the user says the device is mostly used for browsing, coding, office work, or streaming:

- use stronger audit severity

Finding example:

- "Dedicated GPU is likely costing money outside heavy workloads."

#### High-draw peripherals / extras

Trigger when:

- `fanCount >= 5`
- `hasRgb == true`
- external displays >= 2
- user-added peripherals total >= 12 W

Phase 1 heuristic peripheral defaults:

- external monitor: 20 W each, off-bill warning if user clarifies monitor should be excluded
- powered USB hub: 4 W
- webcam/light: 3 W
- speakers/interface: 5 W
- LED strip / external RGB accessory: 4 W

This should generate separate findings only when the estimated monthly cost impact exceeds a small threshold like 3% of monthly PC cost.

#### Idle session waste

Trigger when live tracking history indicates:

- tracked session hours are high
- but productivity or activity signals are low

Phase 1 can approximate using simple Windows signals:

- system locked while tracking continued
- device on AC and app kept running in tray for long periods
- low sampled CPU usage for sustained time

Suggested default idle detector:

- 15-minute rolling window
- CPU average under 8%
- GPU average under 5%
- no foreground full-screen app
- optional screen locked signal

Finding example:

- "Your PC appears to spend long periods in low-activity mode while still tracked as active."

#### Profile mismatch

Trigger when:

- chassis is laptop but profile has desktop-like fan/RGB assumptions
- integrated GPU but very high GPU watts due to stale override
- storage or RAM counts are obviously inconsistent with scan results

This category is not a savings tip first. It is a confidence warning and should prompt profile review.

#### CPU/platform high draw

Trigger when:

- CPU bucket exceeds a threshold portion of total draw, for example >= 35%
- and dailyHours >= 8
- and chassis type is desktop or workstation

This suggests power plan tuning, ECO mode, undervolting, or sleep timers.

#### RGB and fan overhead

Trigger when:

- RGB watts + fan watts >= 10% of total draw

This is especially relevant for custom desktop builds.

### Confidence scoring

Each finding should include:

- `confidence = high | medium | low`

Rules:

- High: backed by saved profile plus direct Windows signal
- Medium: backed by strong profile heuristics only
- Low: result depends on estimated defaults or incomplete data

Low-confidence findings should still show, but with softer wording.

## Per-Component Cost Breakdown

### Component groups

Use stable buckets in UI and storage:

- CPU
- GPU
- RAM
- Storage
- Cooling
- RGB / lighting
- Motherboard / platform
- Peripherals

### Formulas

Given:

- `ratePerKwh`
- `dailyHours`
- `monthlyHours = dailyHours * 30`
- `componentKwhPerMonth = (componentWatts / 1000) * monthlyHours`
- `componentMonthlyCost = componentKwhPerMonth * ratePerKwh`

Then:

- `componentBillShare = componentMonthlyCost / totalMonthlyCost`

### UI expectation

For each component show:

- watts
- estimated monthly cost
- percentage of total estimated bill

Example:

- GPU: `120 W`
- `PHP 311.04 / month`
- `41% of estimated PC electricity cost`

### Rounding

- Store raw doubles
- UI rounds watts to whole numbers
- UI rounds currency to 2 decimals
- UI rounds percentage to nearest whole percent, or 1 decimal if under 10%

## Actionable Tip Generation Logic

Each finding can produce zero or more tips.

Tips should be templated, parameterized, and tied to a numeric savings estimate.

### Tip object fields

- `tipId`
- `findingId`
- `title`
- `body`
- `actionType`
- `estimatedWattsSaved`
- `estimatedMonthlySavings`
- `confidence`
- `dismissedUntil`
- `isDismissed`

### Savings formula

- `monthlySavings = ((estimatedWattsSaved / 1000) * dailyHours * 30) * ratePerKwh`

### Tip templates

#### GPU power limit tip

Trigger when:

- dedicated GPU finding exists
- GPU share of bill >= 25%

Default savings assumption:

- conservative mode: save `min(40 W, gpuWatts * 0.15)`

Example output:

- Title: `Limit GPU power for light workloads`
- Body: `Limiting GPU power to 80% during non-gaming use could save about PHP 180/month.`

#### Frame cap tip

Trigger when:

- dedicated GPU
- user indicates gaming or media usage

Savings assumption:

- save `10%` of GPU watts during gaming share of usage
- if no gaming-share telemetry exists, assume 35% of active hours are high-load for gaming-tagged users

#### Sleep / auto-lock tip

Trigger when:

- idle session waste finding exists

Savings assumption:

- save idle bucket watts during avoidable idle time
- default avoidable idle time = `min(2 hours/day, observedIdleHours)`

Example:

- `Turning on sleep after 15 minutes could save ~PHP 95/month based on your recent idle time.`

#### RGB reduction tip

Trigger when:

- `hasRgb == true`

Savings assumption:

- save full `rgbWatts` for users willing to disable lighting when not needed

#### Fan curve tip

Trigger when:

- `fanCount >= 4`

Savings assumption:

- save `fanWatts * 0.3`

This should be positioned as a low-confidence optimization, because airflow tuning varies.

#### Peripheral shutdown tip

Trigger when:

- peripheral group cost >= threshold

Savings assumption:

- save watts for optional peripherals marked `nonEssential`

### Tip prioritization

Order tips by:

1. highest monthly savings
2. highest confidence
3. lowest user effort

Recommended maximum:

- show top 3 primary tips
- allow `View all tips` for the full list

## Data Model

### New domain models

Recommended files:

- `lib/features/audit/models/energy_audit_result.dart`
- `lib/features/audit/models/audit_finding.dart`
- `lib/features/audit/models/audit_tip.dart`
- `lib/features/audit/models/component_cost_breakdown.dart`
- `lib/features/audit/models/peripheral_profile.dart`

### `ComponentCostBreakdown`

```dart
class ComponentCostBreakdown {
  const ComponentCostBreakdown({
    required this.key,
    required this.label,
    required this.watts,
    required this.monthlyCost,
    required this.billShare,
  });

  final String key;
  final String label;
  final double watts;
  final double monthlyCost;
  final double billShare;
}
```

### `AuditFinding`

```dart
class AuditFinding {
  const AuditFinding({
    required this.id,
    required this.type,
    required this.severity,
    required this.confidence,
    required this.title,
    required this.description,
    required this.estimatedMonthlyImpact,
    required this.componentKeys,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String severity;
  final String confidence;
  final String title;
  final String description;
  final double estimatedMonthlyImpact;
  final List<String> componentKeys;
  final DateTime createdAt;
}
```

### `AuditTip`

```dart
class AuditTip {
  const AuditTip({
    required this.id,
    required this.findingId,
    required this.actionType,
    required this.title,
    required this.body,
    required this.estimatedWattsSaved,
    required this.estimatedMonthlySavings,
    required this.confidence,
    this.dismissedUntil,
    this.isDismissed = false,
  });

  final String id;
  final String findingId;
  final String actionType;
  final String title;
  final String body;
  final double estimatedWattsSaved;
  final double estimatedMonthlySavings;
  final String confidence;
  final DateTime? dismissedUntil;
  final bool isDismissed;
}
```

### `EnergyAuditResult`

```dart
class EnergyAuditResult {
  const EnergyAuditResult({
    required this.id,
    required this.createdAt,
    required this.specSnapshot,
    required this.ratePerKwh,
    required this.currencySymbol,
    required this.dailyHours,
    required this.totalWatts,
    required this.totalMonthlyCost,
    required this.confidence,
    required this.breakdowns,
    required this.findings,
    required this.tips,
    required this.dataCompleteness,
  });

  final String id;
  final DateTime createdAt;
  final Map<String, dynamic> specSnapshot;
  final double ratePerKwh;
  final String currencySymbol;
  final double dailyHours;
  final double totalWatts;
  final double totalMonthlyCost;
  final String confidence;
  final List<ComponentCostBreakdown> breakdowns;
  final List<AuditFinding> findings;
  final List<AuditTip> tips;
  final double dataCompleteness;
}
```

## Hive Storage Schema

### New box

Create a dedicated box:

- `energy_audit`

Recommended keys:

- `latest_result`
- `history`
- `tip_preferences`
- `user_overrides`
- `peripherals`
- `settings`

### Latest audit result

Key:

- `latest_result`

Value:

```json
{
  "id": "audit_2026_04_02T13_20_00Z",
  "created_at": "2026-04-02T13:20:00.000Z",
  "spec_snapshot": {
    "cpu_name": "Intel Core i5-12400",
    "gpu_name": "RTX 3060",
    "gpu_type": "dedicated",
    "ram_gb": 16,
    "ram_sticks": 2,
    "storage_count": 2,
    "storage_type": "SSD",
    "fan_count": 5,
    "has_rgb": true,
    "motherboard": "B660M",
    "chassis_type": "desktop"
  },
  "rate_per_kwh": 13.47,
  "currency_symbol": "PHP ",
  "daily_hours": 8.0,
  "total_watts": 196.0,
  "total_monthly_cost": 634.05,
  "confidence": "medium",
  "data_completeness": 0.86,
  "breakdowns": [],
  "findings": [],
  "tips": []
}
```

### Audit history

Key:

- `history`

Value:

- list of recent result IDs or embedded summaries

Retention recommendation:

- keep latest 20 audits

### Tip preferences

Key:

- `tip_preferences`

Value:

```json
{
  "dismissed_tip_ids": ["tip_rgb_reduce"],
  "snoozed_until": {
    "tip_gpu_limit": "2026-04-09T00:00:00.000Z"
  }
}
```

### User overrides

Key:

- `user_overrides`

Value:

```json
{
  "cpu_watts_override": null,
  "gpu_watts_override": 145.0,
  "motherboard_watts_override": null,
  "rgb_watts_override": 6.0,
  "fan_watts_each_override": 1.8
}
```

### Peripheral profiles

Key:

- `peripherals`

Value:

```json
[
  {
    "id": "monitor_1",
    "label": "27-inch external monitor",
    "category": "display",
    "watts": 20.0,
    "is_essential": false,
    "source": "user"
  }
]
```

### Audit settings

Key:

- `settings`

Value:

```json
{
  "auto_audit_enabled": true,
  "auto_audit_interval_days": 14,
  "show_tips_on_dashboard": true,
  "default_snooze_days": 7
}
```

## UI Flow

### 1. Trigger

User taps:

- `Run energy audit`

Show modal or inline panel:

- `Use saved hardware profile`
- `Include connected peripherals`
- `Use recent activity data if available`

Primary action:

- `Start audit`

### 2. Audit progress state

Show a lightweight progress surface:

- validating hardware profile
- calculating component costs
- generating findings
- generating tips

If Windows sampling is enabled, keep the progress message honest:

- `Sampling current system activity for 15 seconds...`

### 3. Results screen

Recommended page sections:

#### Summary hero

- total estimated monthly cost
- top waste source
- estimated possible monthly savings if top tips are applied

#### Component cost breakdown

- horizontal bars or ranked list
- each row shows watts, cost, bill share

#### Findings section

- grouped by severity
- each card explains why it was flagged

#### Tips section

Each tip card should show:

- title
- savings amount
- confidence badge
- why it matters
- CTA such as `Apply mentally`, `Review settings`, `Learn more`

Card actions:

- `Dismiss`
- `Snooze 7 days`
- `Not relevant`

#### Confidence note

- show if the result depends on heuristic assumptions

Example:

- `Some suggestions are based on estimated idle draw because live GPU telemetry was unavailable.`

### 4. Dashboard integration

After an audit exists:

- dashboard shows top tip banner
- tap opens full audit results

If all tips are dismissed:

- show `Run audit again` instead of a banner

### 5. Tip dismissal and snooze

Dismiss:

- hides tip until next audit run with materially different inputs

Snooze:

- hides tip until a date

Not relevant:

- records a negative preference to avoid repeating the exact recommendation unless the profile changes

## Tip Dismissal Rules

Dismissed tips should reappear only if:

- the audit result changes by more than 10% estimated savings
- relevant hardware changes
- electricity rate changes enough to materially affect impact

Snoozed tips should remain hidden until:

- `dismissedUntil < now`

## Edge Cases

### Incomplete hardware profile

If some fields are missing:

- run the audit anyway
- lower confidence
- show which assumptions were substituted

Example:

- missing motherboard model -> use default motherboard watts

### User overrides conflict with scan data

Rule:

- user overrides always win
- show a subtle `Using your override` note in the audit details

### Integrated GPU devices

Do not show dedicated-GPU power-limit tips when:

- `gpuType == integrated`

### Laptop on battery

If battery state is detected and device is not on AC:

- soften cost-saving language
- shift to efficiency/battery wording

### Zero or invalid rate

If rate is invalid:

- block audit start with a clear message
- offer a shortcut to settings

### Very low-power devices

If total watts < 40 W:

- suppress low-value tips unless bill share is still meaningful

### No telemetry access

If Windows sampling is unavailable:

- fall back to profile-only audit
- mark telemetry-dependent tips as medium or low confidence

### Multi-monitor ambiguity

Displays may not belong to the PC electricity scope the user wants.

Rule:

- ask whether external displays should be included in the audit
- default them to excluded until confirmed

## Implementation Architecture

Recommended new files:

- `lib/features/audit/cubit/energy_audit_cubit.dart`
- `lib/features/audit/cubit/energy_audit_state.dart`
- `lib/features/audit/models/...`
- `lib/features/audit/view/audit_page.dart`
- `lib/features/audit/view/widgets/audit_summary_card.dart`
- `lib/features/audit/view/widgets/component_breakdown_chart.dart`
- `lib/features/audit/view/widgets/audit_finding_card.dart`
- `lib/features/audit/view/widgets/audit_tip_card.dart`
- `lib/data/services/energy_audit_service.dart`
- `lib/data/services/windows_activity_sampler.dart`
- `lib/data/repositories/energy_audit_repository.dart`

### Service split

`EnergyAuditService`

- pure business rules
- takes profile + settings + optional telemetry
- returns `EnergyAuditResult`

`WindowsActivitySampler`

- Windows-only adapter
- optionally samples CPU/GPU/activity state for a short audit window

`EnergyAuditRepository`

- reads/writes Hive data
- exposes latest audit, history, tip preferences, overrides

## Suggested Packages and Windows APIs

Use these only where they add practical value.

### Flutter / Dart packages

- `win32`
  - useful when WattWise needs direct Win32 access through FFI for power state, device status, or deeper Windows integration
- `screen_retriever`
  - useful for display enumeration if monitor-aware audits are added
- `system_theme`
  - optional for matching Windows accent or system visuals if audit surfaces need tighter desktop fit
- `uuid`
  - practical for stable audit, finding, and tip IDs
- `freezed` or `equatable`
  - helpful for immutable audit models and Cubit state transitions
- `hive` / `hive_flutter`
  - continue using existing storage for results and preferences
- existing `local_notifier`
  - already in the app and suitable for surfacing tip reminders or snoozed-tip wakeups

### Windows APIs

- `GetSystemPowerStatus`
  - useful for detecting AC vs battery state for laptops
- `PowerDeterminePlatformRoleEx`
  - useful for validating desktop vs mobile platform assumptions
- `CM_Get_DevNode_Status`
  - useful for checking whether enumerated devices are present and healthy
- PDH performance counters
  - practical option for sampling CPU and GPU engine utilization during the audit window
- existing PowerShell / WMI commands
  - still the simplest path for broad hardware profile collection in this codebase

### Practical recommendation

For Phase 1:

- keep scan logic in PowerShell/WMI
- use `win32` only for signals WMI does poorly, such as direct power-status checks
- use PDH only if a short sampling mode is truly needed

That keeps implementation complexity moderate while still improving audit quality.

## Rules Engine Thresholds

Recommended initial thresholds:

- show finding only if estimated monthly impact >= `ratePerKwh * 0.5`
- show high-severity finding if bill share >= `20%`
- show tip only if estimated monthly savings >= `1%` of total monthly cost or user effort is very low
- treat data completeness below `0.7` as low confidence overall

These should be constants in one place so they can be tuned after internal testing.

## Telemetry Sampling Strategy

If live sampling is implemented, keep it lightweight:

- duration: 10 to 20 seconds
- CPU sample interval: 1 second
- GPU sample interval: 1 second
- lock state sampled once at start and once at end

Do not run continuous background telemetry in Phase 1.

The audit should stay fast, local, and predictable.

## Success Criteria

The feature is successful when:

- the user understands which components dominate their cost
- at least one recommendation is clear and quantified
- the audit can run from saved data in under 1 second without telemetry
- a telemetry-assisted audit completes in under 20 seconds
- dismissed tips stay out of the way
- low-confidence suggestions are clearly labeled

## Sources

- `win32` package on pub.dev: https://pub.dev/packages/win32
- `local_notifier` package on pub.dev: https://pub.dev/packages/local_notifier
- Microsoft Learn, `GetSystemPowerStatus`: https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-getsystempowerstatus
- Microsoft Learn, `PowerDeterminePlatformRoleEx`: https://learn.microsoft.com/tr-tr/windows/win32/api/powerbase/nf-powerbase-powerdetermineplatformroleex
- Microsoft Learn, `CM_Get_DevNode_Status`: https://learn.microsoft.com/en-us/windows/win32/api/cfgmgr32/nf-cfgmgr32-cm_get_devnode_status
- Microsoft Learn, PDH counters: https://learn.microsoft.com/en-us/windows/win32/perfctrs/using-the-pdh-functions-to-consume-counter-data
