You are a senior Flutter developer. Build the complete onboarding flow and live dashboard for a Windows desktop app called WattWise — a real-time PC electricity cost tracker.

--- TECH STACK ---
- Flutter Desktop (Windows only)
- BLoC / Cubit for state management
- Hive for local persistence
- Go Router for navigation
- Material 3, primary color #1D9E75
- dart:io Process.run() for wmic/powershell commands

--- HIVE SETUP ---
Create a HiveBox called 'wattwise_prefs' with these keys:
- 'onboarding_complete' (bool)
- 'cpu_name' (String)
- 'gpu_type' (String: 'integrated' or 'dedicated')
- 'gpu_name' (String)
- 'ram_gb' (int)
- 'ram_sticks' (int)
- 'storage_count' (int)
- 'storage_type' (String: 'SSD' or 'HDD')
- 'fan_count' (int)
- 'has_rgb' (bool)
- 'motherboard' (String)
- 'chassis_type' (String: 'laptop', 'desktop', 'mini_desktop')
- 'electricity_rate' (double) — user's ₱/kWh or any currency
- 'currency_symbol' (String)
- 'daily_hours' (double)

--- ROUTER ---
In router.dart using Go Router:
- '/' → checks onboarding_complete in Hive
  - if false → redirect to '/onboarding'
  - if true → redirect to '/dashboard'
- '/onboarding' → OnboardingShell
- '/dashboard' → DashboardScreen

--- ONBOARDING CUBIT ---
Create OnboardingCubit with OnboardingState containing:
- currentStep (int, 0–6)
- scannedSpecs (SystemSpecModel)
- confirmedSpecs (SystemSpecModel)
- electricityRate (double)
- currencySymbol (String)
- dailyHours (double)
- isScanning (bool)
- scanError (String?)

Methods:
- nextStep()
- previousStep()
- startScan() — runs wmic commands
- confirmSpecs(SystemSpecModel)
- setRate(double rate, String symbol)
- setHours(double hours)
- completeOnboarding() — saves all to Hive, sets onboarding_complete = true

--- SYSTEM SPEC MODEL ---
Create SystemSpecModel with:
- cpuName (String)
- cpuTdpWatts (int) — looked up from a preset map by CPU name keyword
- gpuType (String: 'integrated' or 'dedicated')
- gpuName (String)
- gpuWatts (int) — preset map lookup
- ramGb (int)
- ramSticks (int)
- ramWattsPerStick (int) — default 3W per stick
- storageCount (int)
- storageType (String)
- storageWattsEach (int) — SSD=3W, HDD=7W
- fanCount (int)
- fansWattsEach (int) — default 2W per fan
- hasRgb (bool)
- rgbWatts (int) — default 10W if true
- motherboardWatts (int) — default 50W
- chassisType (String)

Add a computed getter:
- totalWatts → sum of all components
- costPerSecond(double rateKwh) → (totalWatts / 1000) * rateKwh / 3600

--- WMIC SCAN SERVICE ---
Create SystemScanService in lib/data/services/system_scan_service.dart

Run these commands using Process.run('powershell', [...]):

CPU name:
  Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name

GPU name + type:
  Get-WmiObject Win32_VideoController | Select-Object Name, AdapterRAM

RAM total + count:
  Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
  Get-WmiObject Win32_PhysicalMemory | Measure-Object -Sum (count items)

Storage count + type:
  Get-WmiObject Win32_DiskDrive | Select-Object Model, Size

Motherboard:
  Get-WmiObject Win32_BaseBoard | Select-Object -ExpandProperty Product

Parse results into SystemSpecModel.
For GPU type: if AdapterRAM < 2GB or name contains 'Intel' or 'Vega' → integrated, else → dedicated.
For CPU TDP: match cpuName to a preset map (Ryzen 5 5600G → 65W, i5-12400 → 65W, i7-12700K → 125W, etc. — include at least 20 common CPUs).
Wrap everything in try/catch. If a command fails, set that field to a safe default.

--- ONBOARDING SCREENS ---
Create OnboardingShell that wraps a PageView.builder with physics: NeverScrollableScrollPhysics(). Navigation is cubit-driven only.

Show a top progress bar (LinearProgressIndicator) showing currentStep / 6.
Show a back arrow on steps 2+.

STEP 0 — Welcome
- WattWise logo (large bolt icon, color #1D9E75)
- Title: "Know what your PC really costs."
- Subtitle: "WattWise scans your hardware and tracks electricity cost in real time."
- Single button: "Get Started"

STEP 1 — Scanning
- Animated scanning screen using AnimatedBuilder with a rotating CircularProgressIndicator
- Text: "Scanning your system..." then list specs as they are found
- Automatically calls cubit.startScan() on initState
- On scan complete → auto-advance to step 2
- On error → show retry button

STEP 2 — Confirm Specs
- Show all scanned values in editable fields
- Fields: CPU name (read-only), Chassis type (DropdownButton: Laptop / Desktop / Mini Desktop), GPU type (SegmentedButton: Integrated / Dedicated), GPU name (TextField, pre-filled), RAM GB (read-only), RAM sticks (NumberField), Storage count (NumberField), Storage type (SegmentedButton: SSD / HDD), Fan count (Slider 0–10), Has RGB (Switch), Motherboard (read-only)
- Button: "Looks good, continue"

STEP 3 — Terms
- Short disclaimer text:
  "WattWise estimates your electricity cost based on typical hardware wattage values. Results are approximate and not a substitute for a certified energy meter. Actual consumption may vary."
- Checkbox: "I understand this is an estimate"
- Button: "Agree & Continue" (disabled until checkbox checked)

STEP 4 — Electricity Rate
- Label: "What's your electricity rate?"
- Currency symbol TextField (default: ₱)
- Rate TextField (numeric, decimal) with hint "e.g. 13.47"
- Helper text: "Check your latest electric bill for the exact rate."
- Live preview: "At this rate, 1 kWh costs [symbol][rate]"
- Button: "Continue"

STEP 5 — Daily Usage
- Label: "How many hours a day do you use this device?"
- Large Slider (1–24, step 0.5)
- Display selected hours prominently (big number)
- Helper: "Used for daily and monthly cost projections"
- Button: "Continue"

STEP 6 — All Set
- Checkmark animation (AnimatedContainer or Lottie if available)
- Title: "You're all set!"
- Summary card showing: CPU, total watts, rate, hours/day
- Button: "Start Tracking" → calls cubit.completeOnboarding() → navigates to /dashboard

--- DASHBOARD ---
Create DashboardScreen with LiveTimerCubit.

LiveTimerCubit:
- Reads all specs from Hive on init
- Starts a Stream.periodic(Duration(seconds: 1)) ticker
- State contains:
  - elapsedSeconds (int)
  - totalCostAccumulated (double)
  - costPerSecond (double)
  - isRunning (bool)
- Methods: startTimer(), pauseTimer(), resetTimer()

Dashboard UI:
- Top: device name + chassis type chip
- Center: large animated cost display — shows total cost accumulated, ticking up every second (e.g. ₱0.0042 → ₱0.0043)
- Below cost: "₱X.XX per second" in smaller muted text
- Cards row: Per Hour / Per Day / Per Month estimates
- Bottom section: component breakdown list showing each component's watt contribution and cost share
- FAB or top-right button: Pause / Resume timer
- Settings icon → navigate to settings screen

--- FILE STRUCTURE ---
lib/
  main.dart
  app/
    router.dart
    theme.dart
  features/
    onboarding/
      cubit/
        onboarding_cubit.dart
        onboarding_state.dart
      view/
        onboarding_shell.dart
        steps/
          step_0_welcome.dart
          step_1_scanning.dart
          step_2_confirm_specs.dart
          step_3_terms.dart
          step_4_rate.dart
          step_5_hours.dart
          step_6_complete.dart
    dashboard/
      cubit/
        live_timer_cubit.dart
        live_timer_state.dart
      view/
        dashboard_screen.dart
        widgets/
          cost_ticker.dart
          component_breakdown.dart
          estimate_cards.dart
  data/
    models/
      system_spec_model.dart
    services/
      system_scan_service.dart
    repositories/
      wattage_preset_repository.dart
  shared/
    widgets/
    utils/

Generate all files completely. Do not use placeholder comments like '// TODO'. Every file must be fully implemented and runnable.

pubspec.yaml — make sure you have these dependencies added first:

dependencies:
  flutter_bloc: ^8.1.5
  hive_flutter: ^1.1.0
  go_router: ^13.0.0
  equatable: ^2.0.5

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.9