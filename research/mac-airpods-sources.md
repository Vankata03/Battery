# Sources for Mac and AirPods battery

Research for [#8](https://github.com/Vankata03/Battery/issues/8), part of the [Battery 2.0 wayfinder map](https://github.com/Vankata03/Battery/issues/4). Researched 2026-10-12. Terms follow `GLOSSARY.md`: a **Source** is where a **Reading** comes from, and **Health** is capacity relative to design capacity, present only when a Source measures it.

## Question

Which Sources can read Mac battery (level, Health, cycle count, charge state) and AirPods or other Bluetooth accessory battery on macOS and iOS 26–27, public or private? Which of them work inside the Mac App Store sandbox or the iOS sandbox? How do existing Mac apps do it, and are they on the Mac App Store?

## Short answer

- **Mac battery, macOS, sandboxed:** everything Battery 2.1 needs is readable from inside the App Sandbox. Level and charge state come from the public IOPowerSources API. Cycle count and the capacities needed to compute Health come from the `AppleSmartBattery` IORegistry entry, which is read through public IOKit calls but has undocumented keys. Both were verified on macOS 27.0.1 with a sandboxed test app (see [Verification](#verification-run-on-this-mac)). FIPLAB's Battery Health 2, which shows cycle count and capacities, ships on the Mac App Store.
- **AirPods on macOS:** no public API. The candidates are private `IOBluetoothDevice` selectors (`batteryPercentLeft/Right/Case/Single`), parsing Apple's proximity-pairing BLE advertisement through public CoreBluetooth, and scraping `system_profiler` or the unified log. Magic Battery shows AirPods and their case on the Mac App Store, so at least one route passes review; which one it uses is **unverified**. Spawning `system_profiler` from a sandboxed app returned no Bluetooth data in our test.
- **Magic Keyboard, Mouse and Trackpad on macOS:** `BatteryPercent` on `AppleDeviceManagementHIDEventService` in the IORegistry, read the same way as the Mac battery. This is plausibly sandbox-safe; it was not tested with a connected accessory.
- **iOS 26–27:** an app can read only its own Device's battery (`UIDevice`). It cannot read AirPods, Mac, or other Bluetooth accessory battery through any public API. IOPowerSources is not in the iOS 27 SDK headers, and an Apple engineer stated that Bluetooth Classic headset battery is not available through AVFoundation. On iOS, AirPods and Mac Readings can only come from a paired Device, meaning our own Mac app relaying them.
- **Existing apps:** AirBattery (open source) and coconutBattery are distributed outside the Mac App Store. AirBattery is not sandboxed; its entitlements file is empty. Mac App Store apps exist for both the Mac battery (Battery Health 2) and AirPods (Magic Battery, AirMate).

## Mac battery Sources (macOS)

| Source | API status | Gives | Sandbox | Evidence |
|---|---|---|---|---|
| IOPowerSources: `IOPSCopyPowerSourcesInfo`, `IOPSGetPowerSourceDescription`, `IOPSNotificationCreateRunLoopSource` | Public, documented in `IOKit/ps/IOPowerSources.h` and `IOPSKeys.h` | Level (`Current Capacity`/`Max Capacity`, a percentage on Apple silicon), `Is Charging`, `Power Source State` (AC or battery), time to empty and to full, `LPM Active` (Low Power Mode), `DesignCycleCount` | Works (verified) | Probe on macOS 27.0.1; macOS 27 SDK headers |
| IOPowerSources `BatteryHealth` / `BatteryHealthCondition` | Public keys | "Good/Fair/Poor" and a condition string | Not published on Apple silicon (observed `nil`) | Header says Apple sources "will publish this key", but the probe got `nil` on a Mac15,10. Stats reads the key only when `!isARM` |
| IORegistry `AppleSmartBattery` via `IOServiceGetMatchingService` + `IORegistryEntryCreateCFProperty` | IOKit calls are public; the key names are undocumented | `CycleCount`, `DesignCycleCount9C`, `IsCharging`, `ExternalConnected`, `FullyCharged`, `CurrentCapacity`, plus a `BatteryData` dictionary with `DesignCapacity`, `NominalChargeCapacity`, `FullChargeCapacity`, `RemainingCapacity` (mAh) | Works (verified). Reading properties needs no IOKit user client, so no sandbox exception is required | Probe; AirBattery `InternalBattery.swift`; Stats `Modules/Battery/readers.swift` |
| `system_profiler SPPowerDataType` / `ioreg` / `pmset` (spawned) | Command-line tools; output format is not an API | Cycle count, "Condition", "Maximum Capacity %" | `ioreg` spawned from the sandbox worked (verified). Fragile and a likely review problem | Probe |
| SMC (`AppleSMC` user client) | Private | Temperature, raw charger data | Blocked: the sandbox profile has no `iokit-open-user-client` allowance for it | `/System/Library/Sandbox/Profiles/application.sb` (macOS 27.0.1) |

### Notes for Health on the Mac

- On Apple silicon, the top-level `MaxCapacity` is a percentage (observed `100`), not mAh. Older code that reads top-level `DesignCapacity`, `AppleRawMaxCapacity` or `Temperature` gets `nil` on this macOS 27 machine; those values live only inside `BatteryData`, or are absent. AirBattery reads the top-level keys. Stats falls back to `BatteryData`, which is the safer pattern.
- Health computed as `NominalChargeCapacity / DesignCapacity` gave 93% while System Settings showed "Maximum Capacity: 94%". Apple's displayed figure therefore uses some other input or rounding (**unverified** which). If Battery shows this computed value, it should label it as our calculation rather than present it as Apple's number. The glossary already separates measured Health from an estimated-wear Insight.
- The `AppleSmartBattery` keys are undocumented. Apple can rename or move them in any release, and the move into `BatteryData` shows this already happens. Every key needs a `nil` path.

## AirPods and Bluetooth accessory Sources (macOS)

| Source | API status | Gives | Sandbox / Mac App Store | Evidence |
|---|---|---|---|---|
| `IOBluetoothDevice` `batteryPercentLeft`, `batteryPercentRight`, `batteryPercentCase`, `batteryPercentSingle`, `batteryPercentCombined` via KVC | **Private**: exported in `IOBluetooth.tbd` (macOS 27 SDK) but absent from the public headers | Per-bud and case percentage for connected devices | The sandbox allows the Bluetooth daemons with `com.apple.security.device.bluetooth`. Whether this passes review is **unverified**; guideline 2.5.1 says "Apps may only use public APIs" | macOS 27 SDK; AirBattery `MagicBattery.swift` (`getIOBTBattery`) |
| CoreBluetooth scan, parse Apple manufacturer data (company `0x004C`, type `0x07` proximity pairing) | Public API, undocumented payload | Coarse levels: 10% steps for left, right and case, plus charging bits and lid and in-ear state. Only while the AirPods are nearby and advertising | Public API with the Bluetooth entitlement, so plausibly Mac App Store safe (**unverified**) | furiousMAC continuity [proximity_pairing.md](https://github.com/furiousMAC/continuity/blob/master/messages/proximity_pairing.md); AirBattery `BLEBattery.swift` |
| CoreBluetooth GATT Battery Service `0x180F` / Battery Level `0x2A19` | Public, Bluetooth SIG standard | Level for generic BLE accessories that expose the service | Works with the Bluetooth entitlement | AirBattery `BLEBattery.swift`; Stats `Modules/Bluetooth/readers.swift`. AirPods are not known to expose it (**unverified**) |
| IORegistry `AppleDeviceManagementHIDEventService` `BatteryPercent` | Public IOKit calls, undocumented key | Magic Keyboard, Mouse and Trackpad level | Registry reads work in the sandbox; this key was not tested with a Bluetooth accessory connected | AirBattery `MagicBattery.swift`; Stats `readers.swift` |
| `system_profiler SPBluetoothDataType -json` (`device_batteryLevelLeft/Right/Case`) | CLI output | Exact per-bud and case percentage for connected AirPods | Unsandboxed: works (3 battery fields seen for connected AirPods). Sandboxed, with or without the Bluetooth entitlement: 48 bytes of output and no data (verified) | Probe 2 |
| Unified log (`log show`, subsystem `com.apple.bluetooth`) | Log scraping | Battery events for other Bluetooth devices | Not sandbox-compatible in practice; fragile | AirBattery `logReader.sh` |
| `/Library/Preferences/com.apple.Bluetooth.plist` `DeviceCache` `BatteryPercent*` | Undocumented file | Formerly per-device battery | The sandbox allows reading the file with the Bluetooth entitlement, but on macOS 27.0.1 the plist has no `DeviceCache` and no battery keys (observed) | Stats `cacheDevices()`; `plutil` on this Mac |
| `IOBluetoothHandsFreeDevice` `handsFree:batteryCharge:` | Public | 0–5 battery indicator over the Hands-Free Profile | Requires taking an HFP connection, which is impractical for a monitor | macOS 27 SDK header |

AirBattery's `BLEBattery.swift` also reads exact percentages from bytes 14–16 of the 29-byte "lid open" advertisement. The furiousMAC write-up describes the tail of that message as encrypted, and other parsers (AirPodsDesktop, as cited in [HaloBattery PR #42](https://github.com/HeyOkay/HaloBattery/pull/42)) use only the 10% nibbles. Whether macOS delivers those bytes decrypted for paired AirPods is **unverified**. Plan on 10% granularity from advertisements.

## iOS 26–27

| Source | Status | Gives |
|---|---|---|
| `UIDevice.batteryLevel` / `batteryState`, `ProcessInfo.isLowPowerModeEnabled`, `thermalState` | Public | This Device only |
| IOPowerSources | Not in the iOS 27 SDK headers. `IOKit/ps` is missing; symbols exist only in `IOKit.tbd` | n/a (private) |
| AVFoundation output-device battery | Not available. An Apple Media Engineer [said so in 2020](https://developer.apple.com/forums/thread/81807) | n/a |
| CoreBluetooth Battery Service `0x180F` | Public | Generic BLE accessories that expose it. Not AirPods (**unverified** but consistent with the forum answer) |
| CoreBluetooth proximity-pairing advertisement | Public scan API, undocumented payload | **Unverified** whether iOS delivers Apple `0x004C` proximity-pairing data to third-party apps. Even if it does, the iOS 27 header says background scans "must specify one or more service types", and these advertisements carry no service UUID, so it would only work in the foreground |
| AccessorySetupKit, AccessoryNotifications, AccessoryTransportExtension, AudioAccessoryKit, AccessoryLiveActivities (iOS 27 SDK) | Public | Frameworks for third-party accessory makers. A grep of their headers and Swift interfaces found no battery-reading API |
| Apple's Batteries widget | System only | Not available to apps |

So on iOS, AirPods and Mac battery can only arrive from a paired Device, our Mac app, through our own sync. AirBattery does the same between Macs ("Nearcast", built on MultipeerKit with an encrypted payload).

## How existing apps do it

| App | Distribution | Mac battery | AirPods / accessories | iPhone / iPad |
|---|---|---|---|---|
| [AirBattery](https://github.com/lihaoyun6/AirBattery) 1.6.3 (open source) | GitHub releases and Homebrew; empty entitlements, so not sandboxed | IOPowerSources + `AppleSmartBattery` registry | BLE proximity-pairing parse, private `IOBluetoothDevice batteryPercent*`, `system_profiler SPBluetoothDataType`, unified-log scraping, IORegistry `BatteryPercent` for Magic accessories | Bundled libimobiledevice over USB or Wi‑Fi, and `idevicesyslog` for Apple Pencil |
| [Stats](https://github.com/exelban/stats) (open source) | GitHub and Homebrew | IOPowerSources + `AppleSmartBattery` with a `BatteryData` fallback | CoreBluetooth `0x180F`, IORegistry `BatteryPercent`, Bluetooth plist cache, `system_profiler` | – |
| [coconutBattery](https://www.coconut-flavour.com/coconutbattery/) 4.4 (closed) | "only available via coconut-flavour.com" | Yes (method **unverified**, presumably IOKit) | Not advertised | USB, or Wi‑Fi in Plus |
| [Battery Health 2](https://apps.apple.com/us/app/battery-health-2-monitor-battery/id1120214373?mt=12) (FIPLAB, closed) | **Mac App Store** | Cycle count, original and current capacity, temperature, charger | – | – |
| [Magic Battery](https://apps.apple.com/app/id1240063289) 11.0.0 (closed) | **Mac App Store**, macOS 15.6+, Apple silicon | Yes | AirPods and case, Magic accessories, Logitech, Beats, Bose, Sony, BLE. Method **unverified** | "occasionally show up … not officially supported" |
| [AirMate](https://apps.apple.com/jp/app/id1495082233) 1.9.0 (2021, closed) | **Mac App Store** | – | AirPods, Powerbeats, Apple keyboards and mice, BLE ("some devices will not report") | – |

Battery Health 2 shows that a sandboxed app can pass review with cycle count and capacity data. Magic Battery and AirMate show the same for AirPods battery on macOS. Neither publishes how it reads the data.

## Verification run on this Mac

On 2026-10-12, on a Mac15,10 running macOS 27.0.1 (build 26A434) with Xcode 27.0. A small Swift probe was built twice: unsigned, and ad-hoc signed inside an `.app` bundle with `com.apple.security.app-sandbox`. Its container under `~/Library/Containers` was created, which confirms that it ran sandboxed.

- IOPowerSources in the sandbox: level, charging state, power source state, time remaining and `LPM Active` were returned. `BatteryHealth` and `BatteryHealthCondition` were `nil`. `IOPSCopyExternalPowerAdapterDetails` returned `nil` on battery power.
- `AppleSmartBattery` in the sandbox: `CycleCount`, `DesignCycleCount9C`, `IsCharging`, `ExternalConnected`, `FullyCharged`, and `BatteryData.DesignCapacity`, `NominalChargeCapacity` and `FullChargeCapacity` were all returned. The output matched the unsandboxed run.
- `AppleDeviceManagementHIDEventService` in the sandbox: enumerated. Only the internal keyboard was present, without `BatteryPercent`, so no Bluetooth accessory was tested.
- Spawning `/usr/sbin/ioreg` from the sandbox worked.
- Spawning `system_profiler SPBluetoothDataType -json` from the sandbox returned no Bluetooth data, both with and without `com.apple.security.device.bluetooth`. Unsandboxed, it returned per-bud and case levels for the connected AirPods.
- Not run: the private `IOBluetoothDevice batteryPercent*` selectors and CoreBluetooth scanning. Both need a Bluetooth TCC prompt, which could not be answered in a non-interactive session.

The sandbox profile itself (`/System/Library/Sandbox/Profiles/application.sb` and `appsandbox-common.sb`, macOS 27.0.1) allows the Bluetooth daemons `com.apple.bluetoothd`, `com.apple.server.bluetooth.classic.xpc` and `com.apple.server.bluetooth.le.att.xpc` only when the Bluetooth entitlement is present. It allows `com.apple.iokit.powerdxpc` and the `RootDomainUserClient` unconditionally through `(power-assertions)`. Apple marks these files as "System Private Interface", subject to change.

## Implications for Battery 2.0 / 2.1

1. **The Mac app (2.1) can be a sandboxed Mac App Store app for the Mac's own battery.** Use IOPowerSources for level, charge state and Low Power Mode, and IORegistry `AppleSmartBattery` for cycle count and Health inputs. Treat every registry key as optional.
2. **AirPods battery is the risky part.** The only public route is BLE advertisement parsing at 10% granularity, available only while the AirPods are near the Mac. The exact-percentage routes are private (`IOBluetoothDevice`) or blocked by the sandbox (`system_profiler`). Before committing to an AirPods Source, spike two things on a real device with the Bluetooth entitlement: (a) whether the private selectors work from a sandboxed app, and (b) what CoreBluetooth delivers for `0x004C` type `0x07` on macOS 27.
3. **The iPhone app can show Mac and AirPods Readings only when the Mac app relays them.** The iPhone has no Source of its own for them. That relay is the same sync problem as the existing watch link.
4. **Health on the Mac is computed from undocumented values,** and does not exactly match System Settings (93% computed against 94% shown). Decide whether to display it as Health or as an estimate.

## Open items (unverified)

- Which technique Magic Battery and Battery Health 2 use.
- Whether App Review accepts KVC on private `IOBluetoothDevice` selectors in a sandboxed app.
- Whether iOS 26–27 CoreBluetooth surfaces Apple proximity-pairing manufacturer data to apps.
- Whether macOS delivers AirPods advertisement bytes 14–16 decrypted, as AirBattery assumes.
- Which inputs Apple uses for "Maximum Capacity" on Apple silicon.
- Whether `AppleDeviceManagementHIDEventService` `BatteryPercent` is readable in the sandbox with a Bluetooth Magic accessory connected.

## Sources

- macOS 27 SDK (Xcode 27.0): `IOKit.framework/Headers/ps/IOPowerSources.h`, `IOPSKeys.h` (`kIOPSBatteryHealthKey` and related), `IOBluetooth.framework/IOBluetooth.tbd`, `IOBluetooth.framework/Headers/objc/IOBluetoothHandsFreeDevice.h`
- iOS 27 SDK: `IOKit.framework/Headers` (no `ps/`), `IOKit.tbd`, `CoreBluetooth.framework/Headers/CBCentralManager.h`, the Accessory* and AudioAccessoryKit frameworks
- macOS 27.0.1 sandbox profiles: `/System/Library/Sandbox/Profiles/application.sb`, `appsandbox-common.sb`
- App Review Guidelines 2.5.1 and 2.4.5: <https://developer.apple.com/app-store/review/guidelines/>
- Apple Developer Forums thread 81807 (Media Engineer on AVFoundation battery): <https://developer.apple.com/forums/thread/81807>
- AirBattery source: `AirBattery/AirBattery.entitlements`, `BatteryInfo/{BLEBattery,BTDBattery,InternalBattery,MagicBattery,IDeviceBattery}.swift`, `Supports/logReader.sh`, `Supports/Multipeer.swift`, README — <https://github.com/lihaoyun6/AirBattery>
- Stats source: `Modules/Battery/readers.swift`, `Modules/Bluetooth/readers.swift` — <https://github.com/exelban/stats>
- furiousMAC continuity, proximity pairing: <https://github.com/furiousMAC/continuity/blob/master/messages/proximity_pairing.md>
- HaloBattery PR #42 (proximity-pairing nibble layout): <https://github.com/HeyOkay/HaloBattery/pull/42>
- coconutBattery: <https://www.coconut-flavour.com/coconutbattery/>
- Battery Health 2: <https://fiplab.com/apps/battery-health-for-mac>, Mac App Store id1120214373
- Magic Battery, Mac App Store id1240063289; AirMate, Mac App Store id1495082233
