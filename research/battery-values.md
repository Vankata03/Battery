# Battery values reachable on iOS/watchOS 26–27

Research for [#5](https://github.com/Vankata03/Battery/issues/5), part of the [Battery 2.0 wayfinder map](https://github.com/Vankata03/Battery/issues/4). Checked on 2026-10-12 against the Xcode 27.0 (27A266a) SDKs (iOS 27.0, watchOS 27.0), Apple documentation, Apple Support articles, the App Review Guidelines and Apple Developer Forums replies from Apple staff. Terms follow `GLOSSARY.md`: Device, Reading, Source, History, Insight, Health, Surface.

Confidence markers:

- **[SDK]**: read directly from the Xcode 27 SDK headers, Swift interfaces or `.tbd` stubs.
- **[Docs]**: Apple developer documentation, Apple Support or the App Review Guidelines.
- **[Apple staff]**: a reply from an Apple engineer on the Developer Forums.
- **[Observed]**: tested locally for this note.
- **[Unverified]**: third-party report or inference. Needs a device test before anything depends on it.

## Answer in brief

A sandboxed App Store app on iOS 26–27 and watchOS 26–27 can read four values about its own Device: **battery level** (rounded to 5 %), **charge state** (unknown / unplugged / charging / full), **Low Power Mode** (on/off) and **thermal state** (four coarse levels). Nothing else is exposed by a public API: no Health, no cycle count, no charge rate or wattage, no battery temperature, no charge-limit or Optimized Charging state, no time-to-full. The Xcode 27 SDK adds no new battery API for the app's own Device.

The private routes (IOKit power-source calls, the IORegistry, MobileGestalt, analytics logs) either return little from inside the sandbox or cannot be reached at all, and using them breaks App Review Guideline 2.5.1. The only legitimate way to get Health or cycle count into the app is for the person to enter it or to share a file with the app themselves (a user-entry Source).

## Public Sources

### Per-value table

| Value | Source | Platforms | Granularity | Update cadence | Simulator | App Review |
|---|---|---|---|---|---|---|
| Battery level | `UIDevice.batteryLevel` (iOS); `WKInterfaceDevice.batteryLevel` (watchOS) | iOS 3+, watchOS 4+; still the only level API in the 27 SDKs [SDK] | Float 0.0–1.0, rounded to multiples of 0.05 since iOS 17 [Apple staff]; watchOS 10+ reported as also 5 % [Unverified] | iOS: `batteryLevelDidChangeNotification` at most once per minute [Docs]. watchOS: no notification, so poll [SDK] | Returns −1.0 [Observed] | Allowed (public API) |
| Charge state | `UIDevice.batteryState`; `WKInterfaceDevice.batteryState` | Same as above [SDK] | `unknown`, `unplugged`, `charging`, `full` [SDK] | iOS: `batteryStateDidChangeNotification` [Docs]. watchOS: poll [SDK] | `unknown` [Observed] | Allowed |
| Low Power Mode | `ProcessInfo.isLowPowerModeEnabled` | iOS 9+, watchOS 2+ [SDK] | Bool | `NSProcessInfoPowerStateDidChange`, posted on a global queue, iOS and watchOS [SDK] | `false` [Observed] | Allowed |
| Thermal state | `ProcessInfo.thermalState` | iOS 11+, watchOS 4+ [SDK] | `nominal`, `fair`, `serious`, `critical`; device-wide heat, not battery temperature [SDK] | `thermalStateDidChangeNotification`; read the property once before registering [SDK] | `nominal` [Observed] | Allowed |

Notes on the table:

- **Monitoring switch.** Both level and state need `isBatteryMonitoringEnabled = true` first. With monitoring off, state is `unknown` and level is −1.0 [Docs, SDK].
- **The 5 % rounding is intended.** For the iOS 17 change from 1 % to 5 % steps, Apple engineers answered "expected and intended behavior" ([thread 788911](https://developer.apple.com/forums/thread/788911), June 2025) and "Battery level reporting is as accurate as it is intended to be" ([thread 778953](https://developer.apple.com/forums/thread/778953)). For watchOS, the only claim of the same rounding comes from the App Store description of [Juice Watch](https://apps.apple.com/us/app/1485101937): "Since iOS 17 and watchOS 10, Apple shares battery levels with apps rounded to the nearest 5%". Apple has not documented it for watchOS [Unverified].
- **No notifications on watchOS.** `UIDevice` is `API_UNAVAILABLE(watchos)` and both UIKit battery notifications are marked unavailable on watchOS. `WKInterfaceDevice.h` declares no battery notification. A watch app has to poll [SDK].
- **Cadence depends on the app running.** The notifications reach only a running process. A suspended app gets no Readings, so the real cadence is whenever the app, a widget timeline reload or a background task gets runtime. Apple promises no background delivery of battery changes [Inference]. `BGProcessingTaskRequest.requiresExternalPower` can ask to run while plugged in, but the system schedules it at its own discretion [SDK].
- **Apple discourages drain-rate maths.** The `batteryLevelDidChangeNotification` docs say: "Don't attempt to calculate battery drainage rate or battery time remaining; drainage rate can change frequently". Drain rate and time-to-full can still be Insights, but with 5 % steps and gaps in History they must be labelled as estimates [Docs].
- **Simulator.** A bare binary built for the iOS 27 simulator and run with `simctl spawn` on an iPhone 17 Pro simulator printed level −1.0, state `unknown`, LPM `false`, thermal `nominal`. That run was outside a full app process, but it matches the long-standing behaviour. Xcode does not simulate a battery, so level and state need a real Device [Observed]. Thermal state can be forced from Xcode's device-conditions tooling (linked from the `NSProcessInfoThermalState` header) [SDK].
- **Simulator on watchOS.** Not tested. Assume the same as iOS [Unverified].

### Adjacent public Sources (not the app's own Device)

- **Paired Device.** WatchConnectivity can carry the other Device's own public Reading between iPhone and Watch. The current app already does this (`Battery/SessionHandler.swift`, `Battery WatchKit Extension/InterfaceController.swift`). The Juice Watch listing reports that the iPhone level shown on its watch app refreshes "about every 5–60 minutes", which gives a realistic cadence for this route [Unverified].
- **Shortcuts automations.** The person can build a personal automation that fires on Battery Level (Equals / Rises Above / Falls Below a percentage) or on charger connect/disconnect, and that automation can call one of the app's App Intents. This is a user-configured Source that can create Readings while the app is not running ([Shortcuts triggers](https://support.apple.com/guide/shortcuts/setting-triggers-apde31e9638b/ios)) [Docs]. Whether the Shortcuts "Get Battery Level" action is also rounded to 5 % has not been tested [Unverified].
- **EnergyKit.** Present in both 27 SDKs, but it covers grid guidance and electric loads (HVAC, electric vehicles). Its `batteryTemperature` and `batteryHealthManagement` members describe a vehicle's battery that the app reports, not the phone's [SDK]. Not a Source for this app.
- **GameController `GCDeviceBattery`, HomeKit battery characteristics, CarPlay `INGetCarPowerLevelStatus`.** Batteries of controllers, accessories and cars, not of the Device [SDK].
- **AirPods and Mac.** No public API on iOS/watchOS returns their battery. Out of scope here; worth its own ticket if Battery 2.0 keeps them as Devices [Inference].

## Values with no public Source

| Value | What the system shows the person | Public API? |
|---|---|---|
| **Health** (maximum capacity) | Settings › Battery › Battery Health on iPhone 6 and later; on iPhone 15 and later also cycle count, manufacture date and first use ([101575](https://support.apple.com/en-us/101575), [iPhone User Guide](https://support.apple.com/guide/iphone/understand-iphone-battery-usage-health-iphd453d043a/ios)). Apple Watch shows Maximum Capacity under Battery Health ([105080](https://support.apple.com/en-us/105080)) | None [SDK] |
| **Cycle count** | iPhone 15 and later only, in Settings | None [SDK] |
| **Charge rate / wattage** | iOS 26 shows an estimated time to charge (to 80 %, or to 100 %/the limit above 80 %) in Settings and on the Lock Screen. iOS 18+ shows a "Slow Charger" message. No wattage figure is shown ([120619](https://support.apple.com/en-us/120619)) | None [SDK] |
| **Battery temperature** | Not shown. iOS pauses or slows charging outside 0–35 °C ("Thermally Limited Charging", [guide](https://support.apple.com/guide/iphone/understand-thermally-limited-charging-iph3006fbee4/ios)) | None. `thermalState` is the closest proxy and measures something else [SDK] |
| **Charge limit** | iPhone 15 and later: 80–100 % in 5 % steps ([108055](https://support.apple.com/en-us/108055)) | None [SDK] |
| **Optimized Battery Charging** | iPhone (holds at 80 %, learned from at least 14 days of habits; [108055](https://support.apple.com/en-us/108055)); Apple Watch "Optimized Charge Limit", watchOS 10+ ([105106](https://support.apple.com/en-us/105106)) | None [SDK] |
| **Adaptive Power** (iOS 26+) | Settings › Battery › Power Mode ([123707](https://support.apple.com/en-us/123707)) | Not readable. Its one visible effect is switching on Low Power Mode at 20 %, which `isLowPowerModeEnabled` does report [Docs] |

How charge limiting looks through the public API has not been tested. When the limit or Optimized Charging holds the battery below 100 % while plugged in, `batteryState` probably reads `charging` rather than `full` [Unverified]. Apple also says the iPhone "will occasionally charge to 100 percent" with a limit set ([108055](https://support.apple.com/en-us/108055)). Before any Insight infers limiting from a plateau in History, this needs a test on a real iPhone 15 or later.

## Private Sources

App Review Guideline **2.5.1**: "Apps may only use public APIs". Guideline **2.5.2**: apps "may not read or write data outside the designated container area". Either one is enough to reject every route below. Guideline **1.1.6** also forbids "inaccurate device data". An older project, `UIDeviceListener`, warned that battery data it read the same way "will likely get rejected" under the predecessor guideline 2.19 ([README](https://github.com/eldade/UIDeviceListener)) [Docs].

| Source | What it would give | Reachable from the sandbox on iOS 26–27? | App Review |
|---|---|---|---|
| **IOKit power sources** (`IOPSCopyPowerSourcesInfo`, `IOPSGetBatteryHealthState`, `IOPSCopyChargeStatus`, `IOPSLimitBatteryLevel`, `IOPSGetTimeRemainingEstimate` …) | On macOS: level, charging flags, time remaining, health state | The functions are exported in the iOS 27 `IOKit.tbd`, but the iOS SDK ships no `IOKit/ps/` headers, so on iOS they are private [SDK]. Since iOS 10 the power-source dictionary has "nearly all power information" removed ([UIDeviceListener README](https://github.com/eldade/UIDeviceListener)). What a 26/27 sandbox gets back today has not been tested [Unverified] | Rejected under 2.5.1 |
| **IORegistry `AppleSmartBattery`** (CycleCount, DesignCapacity, Temperature, Voltage, InstantAmperage, AdapterDetails) | Health, cycle count, temperature, charge rate | Blocked by the sandbox since around iOS 10; third-party reports agree it no longer works [Unverified] | Rejected under 2.5.1 |
| **MobileGestalt** (`libMobileGestalt`) | Device facts; battery keys reported in the past | `libMobileGestalt.tbd` is in the iOS 27 SDK with no headers, so it is private [SDK]. Battery-key access from the sandbox has not been tested [Unverified] | Rejected under 2.5.1 |
| **Analytics logs** (Settings › Privacy & Security › Analytics & Improvements › Analytics Data) | Battery Health and cycle count in the daily aggregated logs, for any iPhone | The files live outside the app container, so the app cannot read them (2.5.2). The person can open a file there and use **Share** to hand it to the app. This is the method third-party guides describe; the file names and keys change between releases [Unverified] | No rule found against parsing a file the user shares, but whether Review accepts it is not established [Unverified]. Treat it as a user-entry Source |
| **WatchKit / watchOS private frameworks** | None identified | watchOS 27 SDK has no IOKit framework at all [SDK] | Rejected under 2.5.1 |

## Implications for Battery 2.0

- **Reading.** Model a Reading as: level (5 % steps, nullable for −1.0), charge state, Low Power Mode, thermal state, timestamp, Source. Leave Health, cycle count, temperature and charge rate as optional fields that only a user-entry Source fills.
- **Health.** Under the glossary rule ("present only when a Source measures it"), the app never has Health on its own. Health can come from (a) the person typing in the Settings value or (b) a shared analytics file, and should be labelled with that Source and date.
- **Insights** such as drain rate and time to full rest on 5 % steps with gaps. Label them as estimates, in line with Apple's warning against computing drainage rate.
- **Simulator.** Battery features need fakes in the simulator and tests on a real Device; only thermal state can be simulated.
- **Open checks on hardware** (all tagged [Unverified] above): the watchOS 5 % rounding; `batteryState` during a charge limit or Optimized Charging hold; what `IOPSCopyPowerSourcesInfo` returns in a 26/27 sandbox (as a measurement only, never shipped); whether the Shortcuts "Get Battery Level" action is rounded; the format of the analytics file on iOS 26/27.

## Sources

- Xcode 27.0 SDKs: `UIKit/UIDevice.h`, `WatchKit/WKInterfaceDevice.h`, `Foundation/NSProcessInfo.h`, `BackgroundTasks/BGTaskRequest.h`, `IOKit.framework/IOKit.tbd`, `usr/lib/libMobileGestalt.tbd`, `EnergyKit.swiftinterface` (iOS 27.0 and watchOS 27.0).
- Apple Developer Documentation: [UIDevice.batteryLevel](https://developer.apple.com/documentation/uikit/uidevice/batterylevel), [batteryLevelDidChangeNotification](https://developer.apple.com/documentation/uikit/uidevice/batteryleveldidchangenotification), [isBatteryMonitoringEnabled](https://developer.apple.com/documentation/uikit/uidevice/isbatterymonitoringenabled), [WKInterfaceDevice.batteryLevel](https://developer.apple.com/documentation/watchkit/wkinterfacedevice/batterylevel), [ProcessInfo.isLowPowerModeEnabled](https://developer.apple.com/documentation/foundation/processinfo/islowpowermodeenabled).
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/): 1.1.6, 2.4.2, 2.5.1, 2.5.2, 2.5.4.
- Apple Developer Forums: [788911](https://developer.apple.com/forums/thread/788911), [778953](https://developer.apple.com/forums/thread/778953), [738140](https://developer.apple.com/forums/thread/738140).
- Apple Support: [108055 Charge Limit and Optimized Battery Charging](https://support.apple.com/en-us/108055), [101575 iPhone battery and performance](https://support.apple.com/en-us/101575), [120619 iPhone charge speeds](https://support.apple.com/en-us/120619), [123707 Adaptive Power](https://support.apple.com/en-us/123707), [105106 Optimized Battery Charging on Apple Watch](https://support.apple.com/en-us/105106), [105080 Apple Watch battery and performance](https://support.apple.com/en-us/105080), [Battery usage and health](https://support.apple.com/guide/iphone/understand-iphone-battery-usage-health-iphd453d043a/ios), [Thermally Limited Charging](https://support.apple.com/guide/iphone/understand-thermally-limited-charging-iph3006fbee4/ios), [Shortcuts triggers](https://support.apple.com/guide/shortcuts/setting-triggers-apde31e9638b/ios).
- Third party (unverified): [UIDeviceListener](https://github.com/eldade/UIDeviceListener), [Juice Watch App Store listing](https://apps.apple.com/us/app/1485101937).
