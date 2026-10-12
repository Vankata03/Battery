# Competing battery apps: what they offer and charge for

Research for [#7](https://github.com/Vankata03/Battery/issues/7), part of the [Battery 2.0 wayfinder map](https://github.com/Vankata03/Battery/issues/4). Checked on 2026-10-12 against the US App Store. Terms follow `GLOSSARY.md`: Device, Reading, Source, History, Insight, Health, Surface.

## Method and confidence

- **Prices, ratings, versions, release dates, minimum OS and descriptions** come from Apple's iTunes Search and Lookup API (`itunes.apple.com/lookup?id=…&country=us`), which serves the same metadata as the App Store listing. Treat these as verified for the US storefront on the date above.
- **In-app purchase lists and review quotes** come from the public `apps.apple.com` listing pages. A summarising fetch tool extracted them, so wording may be slightly paraphrased and dates should be spot-checked before anyone quotes them publicly. The table marks them *(listing)*.
- **Developer pages and GitHub READMEs** are cited where an app is not on the App Store or the listing is thin.
- Claims marked **[unverified]** come from secondary sources or could not be confirmed against a primary one.
- The Search API ranks results and does not return every app, so the naming section is indicative only. App Store Connect is the authoritative check for whether a name is free.

## Key findings

1. **The "iPhone battery on the Watch" niche is crowded but thin.** At least nine live apps put the iPhone's Reading in a watch complication: Juice Watch, Battery Life, BatteryPhone, Battery Watcher, Remote Battery Level, Unplugged, Batteries – Lock Screen Widget, WristGlint and BatteryBar. Most do only that, plus a threshold notification.
2. **Cross-device hubs all use iCloud, and all run into the same freshness problem.** AllMyBatteries, Cloud Battery, PowerToYou and Battery Life Widgets have an app on every Device, and each one writes its own Reading to iCloud. Their listings admit refresh is "controlled by the system (typically 15–30 minutes)" (PowerToYou), and reviews complain about stale or missing Devices.
3. **Mac hubs get better data by avoiding companion apps.** Batteries for Mac, AirBattery, coconutBattery and Juicy read iPhone and iPad batteries over the local network or USB pairing (libimobiledevice-style), and peripherals over Bluetooth. None of them run on the phone, so none can push to the Watch.
4. **Every iOS and watchOS Source is coarse.** Since iOS 17 and watchOS 10, `UIDevice.batteryLevel` is rounded to 5 % steps. Several listings (Juice Watch, Batteries – Lock Screen Widget, Battery Life Widgets, BatteryMonitorComplication) say so in their descriptions, and an Apple Frameworks Engineer called it "as accurate as it is intended to be" ([forum thread 732903](https://developer.apple.com/forums/thread/732903)).
5. **Insights are rare and shallow.** History graphs are common: 24–72 h in Battery Watcher, up to 7 days in Unplugged. Real Insights are few: drain forecast (Battery Grapher, Unplugged, BatteryMonitorComplication), runtimes from Apple's spec sheet (Battery Life), charging-speed tests (Amperes, Mister Battery). No app combines cross-device History with Insights.
6. **Health is only real where a Source measures it.** On iOS that means importing an Apple analytics log by hand (BAST) or reading Settings yourself (Battery Life's guide). Mac tools read Health directly from the Mac or over USB (coconutBattery, Juicy).
7. **Pricing mostly clusters at a cheap one-time unlock ($1.99–$9.99).** Subscriptions appear in Juice Watch, Unplugged, Remote Battery Level and Battery Health Pro. Ads plus a paywall draw the angriest reviews.
8. **Surfaces in use:** watch complications (nearly all), Home and Lock Screen widgets (most), notifications (all), Smart Stack (Unplugged, WristGlint), Live Activities and Control Center controls (Unplugged only), the Mac menu bar and desktop widgets (Mac tools), Shortcuts and Siri (AllMyBatteries, Cloud Battery, Unplugged, HomeBatteries), and Apple TV (Cloud Battery).

## Apple's built-in baseline

- **iPhone:** the Batteries widget shows the iPhone, a connected Apple Watch and connected accessories such as AirPods. Apple Support: "Add a battery widget on your iPhone to show the charge level of your connected Apple Watch" ([support.apple.com/108760](https://support.apple.com/en-us/108760)).
- **Apple Watch:** Apple's support page for checking Watch battery says nothing about seeing the iPhone's battery from the Watch ([108760](https://support.apple.com/en-us/108760)). That gap is why the whole Watch-complication category exists. **[unverified]** We could not find a first-party Apple source confirming that watchOS 26 has no built-in iPhone-battery complication. Users and app listings say so repeatedly; Unplugged's reviews include "I have often wondered why this feature was not standard."
- **Mac:** a Batteries widget for Mac and Bluetooth peripherals exists in recent macOS. **[unverified]** We did not confirm which Devices it covers.
- **Health** is shown in Settings on iPhone and in Settings on Watch ([Apple Watch guide](https://support.apple.com/guide/watch/check-battery-health-and-usage-apd24c6cb2dd/watchos)). There is no public API for it, which is why BAST asks users to import analytics logs.

## Competitor table

Rating counts are US storefront totals. "Sync" names the Source path a Reading takes to reach another Device.

| App (id) | Developer | Platforms (min OS) | Devices covered | How data is obtained | Surfaces | History / Insights | Price | US rating |
|---|---|---|---|---|---|---|---|---|
| [Battery Life – check runtimes](https://apps.apple.com/us/app/id1080930585) | RBT Digital LLC | iOS 15, watchOS 10 | iPhone, iPad, Watch, AirPods, Bluetooth accessories | On-device `UIDevice` plus Bluetooth/accessory battery; Watch app reads paired iPhone; no cloud | Home and Lock widgets (iOS 17+), complications (Watch, iPhone, combined), notifications | Runtimes from Apple's published specs; guide to iOS Health; thermal state, Low Power Mode | Free + ads; Pro $1.99 one-time *(listing)* | 4.6 (33,813) |
| [AllMyBatteries](https://apps.apple.com/us/app/id1621263412) | 嘉银 李 (Jiayin Li) | iOS 15, macOS 12, watchOS 9, visionOS 1 | iPhone, iPad, Mac, Watch, AirPods, Pencil, Magic accessories, HomeKit, third-party Bluetooth headphones | App on each Device writes to iCloud; "No third-party servers" | Home, Lock and watch-face widgets, Mac menu bar, notifications (low, full, outdated Reading, scheduled), Shortcuts | History with trend chart; sharing with family and friends | Free (3 Devices); Ultimate $6.99, Family $12.99 one-time *(listing)* | 4.5 (2,322) |
| [Cloud Battery](https://apps.apple.com/us/app/id1480648069) | Alan Yan | iOS 18 + Mac, Watch, Vision, tvOS | iPhone, iPad, Mac, Watch, Vision Pro, Apple TV viewer, AirPods and Bluetooth via Mac | iCloud sync; per-Device iCloud sharing with chosen people | Home, Lock, Mac and visionOS widgets, Watch "battery rings", low and ready-to-unplug alerts, App Shortcuts and Siri, Apple TV app | No History or Insights advertised | Free + ads; Remove Ads & Customization $4.99 *(listing)* | 4.0 (1,516) |
| [Battery Widget: PowerToYou](https://apps.apple.com/us/app/id1558154409) | Karandeep Singh | iOS 15, macOS 12, watchOS 9 | iPhone, iPad, Mac, Watch; Bluetooth accessories (macOS only) | Cloud sync; "refresh times are controlled by the system (typically 15–30 minutes)" | Home and Lock widgets, complications, Mac menu bar, low-battery notifications | Battery History tab *(listing)* | $1.99 paid-up-front, universal, no IAP | 3.8 (197) |
| [Battery Life Widgets](https://apps.apple.com/us/app/id6747379512) | Gustavo Amaro dos Reis | iOS 17.6, macOS 15, watchOS 11.5 | iPhone, iPad, MacBook, Watch only | "Entry-based": each Device writes Readings to iCloud; background sync "may be limited by the system" | Home widgets (single, multi, History), Lock widgets, Watch widgets | History charts, Low Power Mode and charging analytics | Free; "Upgraded App Experience" $2.99 *(listing)* | 4.9 (9) |
| [BatteryBar: All Your Batteries](https://apps.apple.com/us/app/id6791232773) | Daisuke Hattori | iOS 18, macOS 15, watchOS 10 | iPhone, iPad, Mac, Watch; Mac's Bluetooth accessories (Pro) | Companion "BatteryBar for Mac"; Bluetooth required. **[unverified]** exact transport | Home widget (up to 4 Devices), notifications; complication is Pro | None advertised | Free; Pro $5.99 one-time *(listing)* | new (0) |
| [Juice Watch](https://apps.apple.com/us/app/id1485101937) | Ganotis Holdings, Inc. | iOS 15, watchOS 9 | iPhone, Watch | WatchConnectivity between paired iPhone and Watch; refresh "about every 5–60 minutes"; complication must be on the active face | Complications (iPhone and Watch together), Home and Lock widgets, charge-threshold and low notifications | None | Free; $5/yr or $25 lifetime; tip jar $0.99–$24.99 *(listing)* | 4.4 (393) |
| [Unplugged: Battery Monitor](https://apps.apple.com/us/app/id6476698892) | Christian Skorobogatow | iOS 26, watchOS 26 | iPhone, Watch | iPhone to Watch; free checks every 2 h, Premium about every 20 min | 12+ complications (4 free), Smart Stack, Live Activities, Control Center controls, Siri, charging animations, notifications with active hours | History 12 h–7 d, on-device ML forecast, thermal state | Free; $1.99/mo, $12.99/yr, $34.99 lifetime *(listing)* | 4.7 (116) |
| [Battery Watcher](https://apps.apple.com/us/app/id987285213) | Slackerz Inc | iOS 18.6, watchOS 11.6 | iPhone → Watch | Watch background refresh | Complications, Time Travel, full-charge alert (Premium) | 24 h and 72 h History graph (Premium) | Free; Premium $1.99 *(listing)* | 4.5 (338) |
| [BatteryPhone](https://apps.apple.com/us/app/id1191334332) | Keietsu Yasuhara | iOS 15, watchOS 8 | iPhone, Watch | Complication refresh "approximately every 12 to 60 minutes"; tap to refresh | Many complication families, notifications | Approximately 24 h graph | Free, no IAP *(listing)* | 3.6 (156) |
| [Remote Battery Level for Watch](https://apps.apple.com/us/app/id954912200) | Caramba App Development | iOS 12, watchOS 3 | iPhone, Watch, plus Wi-Fi or cellular status | iPhone polled about every 30 min | Complications (paid only), alerts | None | Free + ads; $0.49/wk, $0.99/mo, $7.49/yr, $5.99 upgrade *(listing)* | 3.9 (312) |
| [Batteries – Lock Screen Widget](https://apps.apple.com/us/app/id6443457470) | Tobias Hauss | iOS 16, watchOS 9 | iPhone | `UIDevice`; shows when the last Reading on the Watch was taken | Lock widgets, iPhone-battery complications | None | $3.99 paid-up-front | 2.9 (10) |
| [WristGlint: Phone Battery](https://apps.apple.com/us/app/id6808931227) | John Lazarus | iOS 18, watchOS 11 | iPhone | On-demand refresh from the Watch when the iPhone is reachable; shows how old the Reading is | Complications (corner, circular, rectangular, inline), Smart Stack | None | Free | new (0) |
| [Battery Grapher](https://apps.apple.com/us/app/id1498632956) | Joshua Bird | iOS 15, watchOS 9 | the Device it runs on | Hourly background task, no network | All complication and widget sizes; notifications (watchOS) | History plus learned forecast ("hours before needing to charge") | $1.99 | 4.3 (155) |
| [BatteryMonitorComplication](https://apps.apple.com/us/app/id6742497714) | Michael Burch | iOS 17.6 (watch app) | Apple Watch | Reading every 5 % step | Complication with time remaining | Day, night and workout drain rates; cycle statistics; forecast | $0.99 | 5.0 (1) |
| [BAST: Battery Status](https://apps.apple.com/us/app/id1641510005) | Patrick Fezer | iOS 17 | iPhone, iPad, Watch | User imports Apple analytics log files by hand | App only | Health (including above 100 %), cycle count, max and min capacity, production month | Free, no IAP *(listing)* | 4.6 (333) |
| [Battery Health Pro](https://apps.apple.com/us/app/id6753296230) | Cederic Schmid | iOS 18, watchOS 26 | iPhone | Charging sessions tracked; cycle count entered by hand | 3 Home widgets | Charging sessions, thermal, daily/weekly/monthly charts, achievements | Free; $0.99/wk, $3.99/mo, $22.99/yr, $29.99 full *(listing)* | 4.4 (26) |
| [Amperes 4](https://apps.apple.com/us/app/id1245475416) | CrioSoft LLC | iOS 17 | iPhone | Charge-rate measurement | Alarm notification | mA and W charging graphs, charger comparison, global benchmark | $2.99 | 4.4 (649) |
| [HomeBatteries for HomeKit](https://apps.apple.com/us/app/id6450958030) | Adam Foot | iOS 26 | HomeKit accessories | HomeKit framework | Home and Lock widgets, Watch app, notifications, Shortcuts, HomePod via Siri | Battery trends, last charged or replaced | Free + IAP | 4.7 (269) |
| [Batteries for Mac](https://www.fadel.io/batteries) | Rony Fadel | macOS 12.4 | iPhone, iPad, AirPods, Beats, Bluetooth; Watch "limited" | Local Wi-Fi sync with Finder device trust; Bluetooth | Menu bar, Touch Bar, notifications | None | Direct sale via Paddle (10-day trial, 5 Macs per licence) and Setapp; about $8 **[unverified]** | not on Mac App Store (not found via API) |
| [AirBattery](https://github.com/lihaoyun6/AirBattery) | lihaoyun6 | macOS 11 | iPhone, iPad, Watch (via paired iPhone), AirPods, Bluetooth | libimobiledevice over USB or LAN; Bluetooth LE ("Nearbility Engine"); no client app on iOS | Dock, menu bar, widgets, low-battery reminders | None | Free, open source (AGPL-3.0), GitHub and Homebrew | n/a |
| [coconutBattery](https://www.coconut-flavour.com/coconutbattery/) | coconut-flavour.com | macOS 12 | Mac; iPhone and iPad over USB, or Wi-Fi (Plus) | IOKit on Mac; device diagnostics over USB or Wi-Fi | Menu bar, notifications | Health, design capacity, cycle count, lifetime analyser | Free; Plus one-time (Standard or Lifetime) | direct only |
| [Juicy – Battery Alerts & Health](https://apps.apple.com/us/app/id6752221257) | Seven Degrees Labs LLC | macOS 15 | Mac, AirPods (L/R/case), Magic accessories, Beats, iPhone, iPad | Local only, "no cloud storage" *(listing)*. **[unverified]** how iPhone Readings are obtained | Menu bar, desktop and Notification Center widgets, overlay alerts | Mac Health, cycle count, temperature, watts, time remaining | Free; Pro Lifetime $9.99 *(listing)* | too few ratings |

### Delisted or gone

- **Batteries: All Battery Levels** (formerly *Battery Widget 2.0*, Pawan Dixit, id1561658854). Its old `apple.co` link now redirects to that name, but the listing returns 404 and the Lookup API returns nothing in the US, GB, DE and IN storefronts. A secondary source describes it as $7.99 universal, synced "over the internet", with family battery sharing ([AppSpy](https://www.appspy.com/app/89070276/battery-widget-20)). **[unverified]** whether it was removed or is region-limited.

## How competitors obtain data (Sources)

| Source | Who uses it | Limits seen in listings and reviews |
|---|---|---|
| `UIDevice.batteryLevel` and `batteryState` on the Device itself | Everyone on iOS and watchOS | 5 % steps since iOS 17 / watchOS 10 (forum [738140](https://developer.apple.com/forums/thread/738140), [732903](https://developer.apple.com/forums/thread/732903)) |
| WatchConnectivity between iPhone and Watch | Juice Watch, BatteryPhone, Battery Watcher, Remote Battery Level, Unplugged, WristGlint, Batteries – LSW | Refresh 5–60 min; complication must be on the active face (Juice Watch); "Need to open the app on the iPhone in order to sync" (Unplugged review) |
| iCloud (CloudKit or key-value) from an app on each Device | AllMyBatteries, Cloud Battery, PowerToYou, Battery Life Widgets | Needs the app installed on every Device and the same Apple Account; background network limited by the system (Battery Life Widgets); AirPods only via a Mac (PowerToYou) |
| Bluetooth accessory battery | Battery Life (iOS), Mac tools, AllMyBatteries | Mac Bluetooth stack can't read some Devices; no Apple Pencil or Smart Case (Batteries for Mac) |
| Mac reads iPhone/iPad over USB or LAN after trust pairing | Batteries for Mac, AirBattery, coconutBattery | Same LAN and trusted pairing needed; Watch only through its paired iPhone (AirBattery); Mac only |
| Apple analytics log, imported by hand | BAST | Only real Health Source on iOS; manual and multi-step |
| HomeKit | HomeBatteries, AllMyBatteries | Accessory batteries only |

## Notable review complaints

Quotes come from US listing pages *(listing)*.

- **Stale Readings and slow refresh** are the most common complaint.
  - PowerToYou: "It only updates once every 15 minutes … Finding out that my Mac was running out of battery half an hour ago isn't very useful."
  - Juice Watch: "doesn't update for 5 minutes or more."
  - BatteryPhone: "Make the automatic update interval customizable."
- **Notifications don't fire unless the app is opened.**
  - Juice Watch: "only way I've found to get notifications to trigger is to open the Juice Watch app on both my watch and phone."
  - BatteryPhone: "would not notify me until I actually open it."
- **Sync drops Devices.**
  - PowerToYou: AirPods case level never updated after setup.
  - AllMyBatteries: a renamed Watch never syncs its new name, custom icons don't persist, and Shortcuts "Force Sync" times out.
- **Wrong or frozen values.**
  - Batteries – LSW: "the widgets just say 80 %."
  - Remote Battery Level: the complication shows "a question mark."
  - Battery Watcher: 92 % shown when the phone says 94 %, which is the 5 % rounding.
- **Monetisation friction.**
  - Remote Battery Level: "pelted with two ads … before I could even make my way around."
  - Unplugged: "subscription screen EVERY time you open the app. Uninstalled."
  - Battery Life: "an ad is played, like every new action."
  - Battery Health Pro: a full-screen ad pushing paid-only features.
  - An Unplugged lifetime purchase was cancelled by an update.
- **Free-tier caps.** AllMyBatteries limits the free tier to 3 Devices, and Lock Screen widgets show at most 4.
- **Forecast accuracy.** Battery Grapher: "The time remaining is waayyy off" and it predicted "70hrs" at 27 %.
- **Missing features users ask for.** Unplugged users want location-aware charging reminders ("hard to believe this isn't already a feature"), and Batteries – LSW users want more widget customisation.

## Gaps Battery 2.0 could fill

1. **Cross-device History with real Insights.** The hubs have a level and at most a chart. Forecast apps cover only the Device they run on. No app offers drain rate, time to full or charging-habit hints across iPhone, Watch, Mac and AirPods together.
2. **Honest freshness.** Only WristGlint and Batteries – LSW show how old a Reading is. Most complaints are really about staleness the app hides. Showing the Reading's age on every Surface, as AllMyBatteries' "outdated reading" alert starts to do, deals with the main complaint directly.
3. **Health versus estimate.** No iOS app separates measured Health (only from logs or the Mac) from estimated wear. The glossary already draws that line.
4. **Modern Surfaces.** Only Unplugged uses Live Activities, Control Center controls and Smart Stack together, and it covers only the iPhone and Watch pair. No cross-device hub uses controls or Live Activities.
5. **A Mac-side Source feeding the Watch.** Mac tools read iPhone, iPad and AirPods well but never reach the Watch. iOS hubs reach the Watch but read AirPods poorly. A Mac app that publishes its Bluetooth Readings to the shared store would close this gap. AllMyBatteries and PowerToYou claim to do this; reviews say it is unreliable.
6. **Fair pricing.** The best-reviewed apps charge one-time prices from $1.99 to $9.99 with no ads (PowerToYou, Battery Grapher, AllMyBatteries). Subscriptions and ads draw one-star reviews.

## Names around "Battery" already taken

Exact or base-name matches in the US App Store Search API (iOS and Mac), 2026-10-12. Indicative only.

| Candidate name | Status |
|---|---|
| Battery | No app with exactly this base name in the top 200 results. Bare-word names are often blocked in App Store Connect anyway. **[unverified]** |
| Batteries | Taken in practice: "Batteries – Lock Screen Widget" (Tobias Hauss). Battery Life Widgets calls itself "Batteries" in its description. "Batteries for Mac" (Rony Fadel) is sold outside the store. "Batteries: All Battery Levels" (id1561658854) may be delisted. |
| Battery Life | "Battery Life – check runtimes" (RBT Digital, the category leader) |
| Battery Widget | "Battery Widget: PowerToYou", "Battery Widget: CPU x Monitor", "Battery Widget: Emoji", "Battery Widget" (Mac, Marian Raafat) |
| Battery Watch | "Battery Watch – Battery And Storage Tracker" (2015); "Battery Watcher" (Slackerz); "Battery Watch for Apple Watch" (2015) |
| Battery Monitor | Several: Marcel Bresink (Mac), Rocky Sand (Mac), Tom Etminan, "Battery Monitor – Bluetooth", plus many automotive and BMS apps |
| Battery Status | "Battery Status-check runtimes" (BAI LONGMA); BAST uses it as a subtitle |
| Battery Level | "Battery Level – Portal"; "Battery Level Widget" (Beatcode) |
| Battery Buddy | "Battery Buddy" (Minh Ngoc Nguyen) |
| BatteryBar / Battery Bar | "BatteryBar: All Your Batteries" (Daisuke Hattori) |
| Cloud Battery, AllMyBatteries, Juice Watch, BatteryPhone, Battery Grapher, Battery Indicator (Sorhus), Battery Clock, Battery Charge Alarm, Mister Battery | Taken |
| Juice, Charge | Base names used by unrelated apps (Juice – Beauty Camera; CHARGE – EV, Charge: POS) |
| My Batteries, All Batteries, Battery Hub, Battery Sync, Battery Pal, Battery Glance, Batteries Widget, Battery 2 | No base-name match found. "Battery Hub for HomeKit" and "Battery Monitor Sync" are near-collisions. |

## Sources

- iTunes Search and Lookup API, US storefront, 2026-10-12: `https://itunes.apple.com/lookup?id=<id>&country=us` and `https://itunes.apple.com/search?term=<term>&entity=software|macSoftware`
- App Store listings: [Battery Life](https://apps.apple.com/us/app/id1080930585), [AllMyBatteries](https://apps.apple.com/us/app/id1621263412), [Cloud Battery](https://apps.apple.com/us/app/cloud-battery/id1480648069), [PowerToYou](https://apps.apple.com/us/app/battery-widget-powertoyou/id1558154409), [Battery Life Widgets](https://apps.apple.com/app/id6747379512), [BatteryBar](https://apps.apple.com/us/app/batterybar-all-your-batteries/id6791232773), [Juice Watch](https://apps.apple.com/us/app/juice-watch/id1485101937), [Unplugged](https://apps.apple.com/us/app/id6476698892), [Battery Watcher](https://apps.apple.com/us/app/battery-watcher/id987285213), [BatteryPhone](https://apps.apple.com/us/app/batteryphone/id1191334332), [Remote Battery Level](https://apps.apple.com/us/app/remote-battery-level-for-watch/id954912200), [Batteries – Lock Screen Widget](https://apps.apple.com/us/app/id6443457470), [WristGlint](https://apps.apple.com/us/app/id6808931227), [Battery Grapher](https://apps.apple.com/us/app/battery-grapher/id1498632956), [BatteryMonitorComplication](https://apps.apple.com/us/app/id6742497714), [BAST](https://apps.apple.com/us/app/bast-battery-status/id1641510005), [Battery Health Pro](https://apps.apple.com/us/app/battery-health-pro/id6753296230), [Amperes 4](https://apps.apple.com/us/app/id1245475416), [HomeBatteries](https://apps.apple.com/us/app/id6450958030), [Juicy](https://apps.apple.com/us/app/battery-alerts-health-juicy/id6752221257), [Battery Indicator](https://apps.apple.com/us/app/id1206020918)
- Developer pages: [juicewatch.app](https://juicewatch.app/), [powertoyou.ksapps.com](https://powertoyou.ksapps.com), [allmybatteries.jylljy.com](https://allmybatteries.jylljy.com), [alanyan.ca/cloudbattery](https://www.alanyan.ca/cloudbattery/), [fadel.io/batteries](https://www.fadel.io/batteries), [github.com/lihaoyun6/AirBattery](https://github.com/lihaoyun6/AirBattery), [coconut-flavour.com/coconutbattery](https://www.coconut-flavour.com/coconutbattery/), [getjuicy.app](https://getjuicy.app), [batterylifeapp.com](https://www.batterylifeapp.com)
- Apple: [Check your battery and charge your Apple Watch (108760)](https://support.apple.com/en-us/108760); [Apple Watch battery health guide](https://support.apple.com/guide/watch/check-battery-health-and-usage-apd24c6cb2dd/watchos); Developer Forums [738140](https://developer.apple.com/forums/thread/738140) and [732903](https://developer.apple.com/forums/thread/732903) (Frameworks Engineer, Jun 2023: "Battery level reporting is as accurate as it is intended to be"; DTS, Apr 2025: "The API does not specify the degree to which the battery level value is rounded")
- Secondary, used only where marked: [AppSpy – Battery Widget 2.0](https://www.appspy.com/app/89070276/battery-widget-20); appgefahren and ifun.de on Batteries for Mac pricing
