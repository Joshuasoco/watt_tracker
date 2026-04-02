# What Is WattWise?

`WattWise` is the user-facing name of this app, while `watt_tracker` is the Flutter package and repository name.

In simple terms, WattWise is a desktop app that estimates how much electricity a PC costs to run in real time.

## What the app does

- Scans the machine's hardware on onboarding using Windows system commands.
- Builds a power estimate from the detected CPU, GPU, RAM, storage, fans, RGB, and motherboard.
- Lets the user confirm or adjust the detected hardware profile.
- Stores the electricity rate, currency symbol, and daily usage hours in Hive.
- Shows a live session cost ticker on the dashboard.
- Calculates projected cost per hour, per day, and per month.
- Can stay active in the Windows system tray so tracking continues after the main window is hidden.
- Supports session milestone notifications.

## How the app works today

The current app flow is:

1. Onboarding
2. Hardware scan and confirmation
3. Electricity rate and daily usage setup
4. Live dashboard
5. Settings for updating tracking preferences

Routing currently sends new users to onboarding and returning users to the dashboard.

## Why the project has two names

- `WattWise`: the product/app branding shown in the UI, window title, notifications, and tray menu.
- `watt_tracker`: the technical/project identifier used in `pubspec.yaml` and the folder name.

That means both names refer to the same project, but `WattWise` is the better name to use in documentation and UI copy.

## Short description you can reuse

WattWise is a Flutter desktop app for Windows that estimates a computer's power draw and tracks electricity cost in real time using a saved hardware profile, local preferences, and a live session timer.
