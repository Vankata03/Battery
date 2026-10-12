# How the phone's Readings reach the watch while the iPhone app is suspended

Research for [#6](https://github.com/Vankata03/Battery/issues/6), part of the [Battery 2.0 wayfinder map](https://github.com/Vankata03/Battery/issues/4). Researched 2026-10-12 against the iOS 26 / watchOS 26 documentation set. Vocabulary follows `GLOSSARY.md`.

Claims are tagged:

- **[doc]**: current Apple developer documentation.
- **[WWDC]**: a WWDC session transcript.
- **[Apple eng]**: an Apple engineer (DTS, Frameworks Engineer, WWDR) answering on the Apple Developer Forums.
- **[legacy doc]**: archived Apple documentation that is no longer maintained but has not been contradicted.
- **[third party]**: an App Store listing or developer report. Treat as evidence of what is achievable, not as a guarantee.
- **[unverified]**: inference or a claim no primary source confirms. Each one needs a prototype before the spec relies on it.

## Short answer

There is no public mechanism that lets a suspended iPhone app react to a battery change, and nothing lets the iPhone push a Reading to the watch on its own schedule. A phone Reading reaches the watch only when something gives the iPhone app runtime, and then it reaches a watch Surface only when something gives the watch app runtime. Both sides are budgeted and opportunistic.

Realistic freshness for the **iPhone's Reading on the watch**:

| Watch Surface | Typical age of the phone Reading | Worst case |
|---|---|---|
| Watch app in the foreground | Seconds. The watch asks the phone directly. | Phone out of range: last received Reading. |
| Complication on the active face | 15–60 minutes when the iPhone app gets runtime regularly | Hours, or until the user opens either app |
| Smart Stack widget | Same or worse than the complication. WatchConnectivity cannot target it. | Hours |

Competing apps advertise the same envelope: Juice Watch says readings "typically refresh every 5 to 60 minutes in 5 percent increments", and BatteryPhone says "approximately every 12 to 60 minutes" and "limited to 50 times per day" **[third party]**.

The **iPhone's own widgets** do not depend on the app running. Their extension can read the battery at each timeline reload (40–70 reloads a day, roughly every 15–60 minutes). The **watch's Reading on the iPhone** has the same problem in reverse: the iPhone app only receives it when the iPhone app runs, and the iPhone widget extension cannot use WatchConnectivity.

Design consequence: every Surface must show a Reading's age, and the spec should promise "recent", not "live", except inside the foreground apps.

## 1. Battery-change notifications and a suspended iPhone app

- `UIDevice.batteryLevelDidChangeNotification` and `batteryStateDidChangeNotification` fire only when `isBatteryMonitoringEnabled` is `true`. Level notifications are "sent no more frequently than once per minute" **[doc]**.
- A suspended app "does not execute any code". iOS queues battery-level and battery-state notifications and delivers one coalesced notification of each type when the app next runs, in the foreground or the background **[legacy doc: App Programming Guide for iOS, "Be Prepared to Process Queued Notifications", Table 4-1]**. The notifications never wake the app.
- Since iOS 17, `UIDevice.batteryLevel` changes in 5% steps. An Apple Frameworks Engineer called this "expected and intended behavior" (June 2025) **[Apple eng]**. A full discharge therefore produces about 20 distinct levels, plus charge-state changes.
- Quinn (DTS) lists what iOS does not offer: no general mechanism to run "continuously in the background", "at some specific time", "periodically at a guaranteed interval", or to resume "in response to a network or IPC request". Force-quitting from the app switcher also blocks background launches until the user opens the app again **[Apple eng: forum thread 685525, updated 2026-01-09]**.

**Conclusion:** battery events are not a trigger. The iPhone app sees the current Reading whenever it happens to run.

## 2. What gives the iPhone app runtime while it is suspended

| Mechanism | What it gives | Limits | Fit for Battery |
|---|---|---|---|
| `BGAppRefreshTask` | Up to 30 s of runtime at a time the system picks **[doc]** | Heuristic, tied to how often the user opens the app. Quinn: "there are common scenarios where it won't grant you *any* background execution time at all" **[Apple eng]**. Turned off by Low Power Mode **[doc: support.apple.com/101604]** and by force quit. | Main baseline. Unpredictable. Weakest on low battery, exactly when users care. |
| Background push (`content-available`) | 30 s of runtime per delivered push **[doc]** | Needs a server. "Don't try to send more than two or three per hour"; low priority, no delivery guarantee, only the newest held push survives **[doc]**. | A server-sent "heartbeat" would wake the app about 2–3 times an hour at best. It costs money, and using pushes that carry no new content is a questionable fit for their intended purpose **[unverified: App Review risk]**. |
| `sendMessage` from the watch | Wakes the iPhone app in the background and makes it reachable **[doc: `sendMessage(_:replyHandler:errorHandler:)`]** | Only while the watch app is foreground or in a high-priority background state such as a workout (see `isReachable`) **[doc]** | Works well for the foreground watch app. Does not help complications. |
| Shortcuts personal automations | The user creates "Battery Level" (Equals, Rises Above, Falls Below a %) and "Charger" (Connected, Disconnected) automations **[doc: Shortcuts User Guide, "Setting triggers"]** that run an App Intent Battery provides | Manual setup, one automation per threshold. Whether they run without a prompt on iOS 26 **[unverified]**. Whether an App Intent running in the background can use `WCSession` **[unverified]** (an App Intents *extension* cannot). | The only event-driven trigger tied to battery changes. Worth offering as opt-in "precise mode". Needs a prototype. |
| `BGContinuedProcessingTaskRequest` (iOS 26) | Long-running work that continues after backgrounding **[doc]** | Must start from a user action in the foreground and is meant for finite jobs | No fit. Battery has nothing to process. |
| Background modes: location, audio, VoIP, Bluetooth | Keep the app alive or relaunch it | Guideline 2.5.4: background services only "for their intended purposes" **[doc: App Review Guidelines]** | Rejected. Abusing them is a review and account risk; issue #4 already requires review-safe code. |

## 3. WatchConnectivity: getting a Reading from phone to watch

All transfers need an activated `WCSession` in the **main iOS app**. App extensions, including widget extensions, cannot use it **[unverified: widely reported, no Apple statement found]**.

| API | Behaviour | Budget | Wakes the watch app? |
|---|---|---|---|
| `updateApplicationContext(_:)` | Replaces the previous dictionary. "Well suited" for state that changes often. The counterpart can read `receivedApplicationContext` **[doc]**. | None documented | Documented: it triggers a `WKWatchConnectivityRefreshBackgroundTask` **[doc]**. In practice see the warning below. |
| `transferUserInfo(_:)` | Queued, FIFO, delivery guaranteed, "continues even if the app is suspended" **[doc]** | None documented | Same as above. |
| `transferCurrentComplicationUserInfo(_:)` | High priority, sent right away **[doc]** | **50 per day**, and only while the complication is on the active watch face. Otherwise `remainingComplicationUserInfoTransfers` is 0 and calls fall back to `transferUserInfo` **[doc]**. `isComplicationEnabled` is `false` when the widget is only in the Smart Stack **[Apple eng: thread 745581]**. | Should. **Does not with WidgetKit complications** (see below). |
| `sendMessage(_:replyHandler:errorHandler:)` | Immediate, needs `isReachable` **[doc]** | None | "Calling this method from your iOS app does not wake up the corresponding WatchKit extension" **[doc]**. Only useful phone→watch while the watch app is already running. |

**Warning: complication transfers are broken for WidgetKit complications.** ClockKit is gone, so every watchOS 26 complication is a WidgetKit complication. Apple engineers have repeatedly confirmed the problem:

- "`transferCurrentComplicationUserInfo()` does not currently work with WidgetKit-based complications" (Frameworks Engineer, July 2024, [thread 759389](https://developer.apple.com/forums/thread/759389)) **[Apple eng]**.
- "doesn't work with WidgetKit complications for now, and that is a bug on the framework side" (DTS, March 2024, [thread 743829](https://developer.apple.com/forums/thread/743829)) **[Apple eng]**.
- June 2025: a developer using `transferUserInfo` reports complications only update after opening the watch app. DTS (Ziqiao Chen) answered that "the issue was confirmed" and asked for feedback ([thread 789024](https://developer.apple.com/forums/thread/789024)) **[Apple eng]**.
- No source says this is fixed in watchOS 26 **[unverified: must be tested on watchOS 26/27 hardware]**.

For the Smart Stack, a Frameworks Engineer said: "widgets in the Smart Stack are not complications… WatchConnectivity is not an option for updating widgets" (February 2024, [thread 745581](https://developer.apple.com/forums/thread/745581)) **[Apple eng]**.

**Practical chain that does work, per the documentation** (each step needs a prototype on current OS versions):

1. Whenever the iPhone app runs, for any reason in section 2, it reads the battery and calls `updateApplicationContext` with the latest Reading. If the complication is active and budget remains, it also calls `transferCurrentComplicationUserInfo`, which costs nothing and may start working again.
2. The watch app gets runtime from its own background refresh. `WKApplicationRefreshBackgroundTask` gives "approximately four tasks per hour for each app with a complication on the active watch face" **[doc]**. Without a complication on the active face the app gets **no** background refresh time **[doc: "Using background tasks"]**. WWDC20 adds: at most 4 s of CPU and 15 s wall time per task **[WWDC20 10049]**.
3. In that task the watch app activates `WCSession`, takes the pending context (the delegate is called "shortly after you activate the session" when context is waiting **[doc]**), stores it in the App Group, and calls `WidgetCenter.reloadTimelines(ofKind:)`.
4. The reload is budgeted. Apple documents 40–70 reloads per day for a frequently viewed widget **[doc]**. A third-party summary claims up to 75 a day for watch complications **[unverified]**. Four reloads an hour (about 64 waking-hour reloads) fits inside that.

Step 2 bounds complication freshness at 15 minutes at best. Step 1 sets the real bound: the phone Reading is only as fresh as the iPhone app's last run.

## 4. WidgetKit reload budgets

- Each placed widget has its own 24-hour budget, tuned to the user's daily pattern. A frequently viewed widget typically gets **40–70 refreshes per day, about every 15–60 minutes**. Timeline entries should be at least about 5 minutes apart **[doc: "Keeping a widget up to date"; WWDC21 "Principles of great widgets"]**.
- Reloads are free while the containing app is in the foreground, during audio or navigation sessions, and during app-intent interactions **[doc]**. On watchOS, reloads during a running `HKWorkoutSession` are also free (DTS, March 2026, [thread 819899](https://developer.apple.com/forums/thread/819899)) **[Apple eng]**. Battery cannot legitimately use workout sessions.
- WidgetKit lowers reloads for widgets on rarely visited pages and reloads them when they become visible **[doc]**.
- WidgetKit developer mode (Settings) ignores budgets during development **[WWDC25 "What's new in widgets"]**. Field testing must turn it off.
- **iPhone widgets showing the iPhone's own Reading** can read `UIDevice.batteryLevel` in the widget extension at each reload, so they do not need the app to run **[unverified: common practice, no Apple statement; prototype]**. Without the app they reach the 40–70 per day envelope. A reload is free whenever the app is in the foreground.

## 5. Push-based updates (WidgetKit push, control push)

- New in iOS 26 and watchOS 26: `WidgetPushHandler` and `.pushHandler(_:)` on widget configurations **[doc]**. A server sends an APNs request with `apns-push-type: widgets`, topic `<bundleID>.push-type.widgets`, and `"content-changed": true`. WidgetKit then reloads timelines as if `reloadAllTimelines()` were called **[doc]**.
- These pushes are "budgeted" and delivered "opportunistically". They are "an additional update mechanism… that doesn't replace timeline updates" **[doc]**. Broadcast channels are not supported **[doc]**.
- Controls have the equivalent `ControlPushHandler` (iOS 18+, watchOS 26+) **[doc]**.
- WWDC20 described server "complication pushes" capped at 50 per watch per day **[WWDC20 10049]**. They belong to the ClockKit and PushKit era. Whether that path still works for WidgetKit complications is **[unverified]**, and WidgetKit push is its replacement.

**What push does and does not solve.** Push moves a *server's* knowledge to a widget. It does not help phone→watch, because the server only learns the phone's Reading when the phone app runs, which is the same bottleneck. It *does* help the reverse direction and the 2.1 cross-device sync: the watch app can upload its Reading by background `URLSession` (up to about 4 requests an hour **[WWDC20 10049]**), and the server can push-reload the iPhone widget, whose extension fetches the Reading over the network (widgets and complications have network access **[doc]**). The cost is a server, APNs token handling, and privacy work for a free app. This belongs to the sync research, not to 2.0.

## 6. The reverse direction: the watch's Reading on the iPhone

- The watch app reads its own battery through `WKInterfaceDevice.batteryLevel` after enabling `isBatteryMonitoringEnabled` **[doc]**. Watch complications can show the watch's own Reading with roughly 15-minute freshness, based on the background refresh rate.
- From a background refresh task the watch can call `updateApplicationContext` or `transferUserInfo` toward the phone.
- Whether that **wakes the iPhone app** is unclear. In WWDC15 ("Introducing Watch Connectivity") Apple said that for background transfers "we will wait until the app on the iOS side launches. And when it does, we will deliver that content" **[WWDC15 713]**. A DTS answer from October 2024 recommends `transferUserInfo` with `session(_:didReceiveUserInfo:)` for data "received in background", but never says the iPhone app gets launched for it ([thread 766559](https://developer.apple.com/forums/thread/766559)) **[unverified]**.
- `sendMessage` from the watch *does* wake the iPhone app in the background **[doc]**, but only while the watch app is reachable (foreground or workout), not during a background refresh **[doc: `isReachable`]**. So opening the watch app pushes a fresh watch Reading to the phone and pulls a fresh phone Reading back in one round trip.
- iPhone widgets cannot receive WatchConnectivity data themselves. A widget showing the watch's Reading is only as fresh as the iPhone app's last run, unless the server relay from section 5 is built.

## 7. What existing apps do

- **BatteryPhone** (Keietsu Yasuhara): complication shows phone and watch, "updated approximately every 12 to 60 minutes", "limited to 50 times per day (iOS restriction)". If updates stop for 1.5+ hours, the user should "tap the complication to restart it" **[third party: App Store listing]**. The 50-per-day figure matches `transferCurrentComplicationUserInfo`, and "tap to restart" matches the foreground-wake workaround.
- **Juice Watch**: "readings are periodic rather than real-time and typically refresh every 5 to 60 minutes in 5 percent increments". It shows "when each reading was received" and "when each reading was updated" **[third party: juicewatch.app]**.
- Neither app claims real-time complications. Both expose the Reading's age, which is the pattern Battery 2.0 should copy.

## 8. Recommendations for the spec

1. **Model staleness as a first-class property of a Reading.** Each Reading stores when it was measured and when it arrived; every Surface shows its age and dims or flags it beyond a threshold (for example 60 minutes).
2. **Foreground apps are live.** The watch app sends `sendMessage` on appear to wake the phone and get a fresh phone Reading. The iPhone app pushes context on every launch and resume.
3. **iPhone app, whenever it runs:** read the battery, call `updateApplicationContext` with the latest phone Reading (and a short History tail), call `transferCurrentComplicationUserInfo` when `isComplicationEnabled` and budget remains, and reload its own widgets.
4. **Schedule `BGAppRefreshTask`** as the baseline and accept that it is unreliable, and turned off by Low Power Mode.
5. **Watch app background refresh** (needs a complication on the active face): read the watch battery, collect pending context, write the App Group, reload complications and Smart Stack widgets, and send the watch Reading to the phone with `updateApplicationContext`.
6. **iPhone widgets read the phone battery locally** in the extension instead of waiting for the app.
7. **Optional "precise mode"** through Shortcuts battery and charger automations that run a Battery App Intent. Opt-in, set up during onboarding.
8. **No background-mode abuse and no heartbeat pushes in 2.0.** Leave the server relay with WidgetKit push to the 2.1 sync decision.
9. **Copy:** describe Surfaces as "updates every 15–60 minutes", never "real time".

## 9. Prototype checklist (blocking for #11, #12, #13)

Run on physical devices with iOS 26 and watchOS 26 (and the 27 betas), with WidgetKit developer mode **off**:

- [ ] Does `transferCurrentComplicationUserInfo` or `updateApplicationContext` wake the watch app and reload a WidgetKit complication while the watch app is not running? (Known broken through June 2025.)
- [ ] Does the watch background refresh task see pending application context and successfully call `reloadTimelines`? Measure the real interval over 24 hours.
- [ ] Does a watch→phone `transferUserInfo` or `updateApplicationContext` launch a suspended or terminated iPhone app?
- [ ] Can an iPhone widget extension read `UIDevice.batteryLevel` and `batteryState`? Measure real reload intervals over 24 hours.
- [ ] Measure how often `BGAppRefreshTask` actually fires for a rarely opened app, with Low Power Mode on and off.
- [ ] Do Shortcuts battery and charger automations run a background App Intent without a prompt, and can that intent use `WCSession`?
- [ ] Do iPhone-provided controls on watchOS 26 (Control Center or Smart Stack) evaluate their value provider on the iPhone? If so, they could show a fresher phone Reading on the watch **[unverified: speculative]**.

## Sources

Apple documentation (developer.apple.com/documentation):

- UIKit: `UIDevice.batteryLevelDidChangeNotification`, `batteryStateDidChangeNotification`, `isBatteryMonitoringEnabled`, `batteryLevel`
- WatchConnectivity: `WCSession`, `updateApplicationContext(_:)`, `transferUserInfo(_:)`, `transferCurrentComplicationUserInfo(_:)`, `remainingComplicationUserInfoTransfers`, `isComplicationEnabled`, `isReachable`, `sendMessage(_:replyHandler:errorHandler:)`, `session(_:didReceiveApplicationContext:)`; sample "Transferring data with Watch Connectivity"
- WatchKit: "Using background tasks", `WKApplicationRefreshBackgroundTask`, `WKWatchConnectivityRefreshBackgroundTask`, `scheduleBackgroundRefresh(withPreferredDate:userInfo:scheduledCompletion:)`, `WKInterfaceDevice.batteryLevel`
- WidgetKit: "Keeping a widget up to date", "Updating widgets with WidgetKit push notifications", `WidgetPushHandler`, "Developing a WidgetKit strategy", "Updating controls locally and remotely", `ControlPushHandler`
- BackgroundTasks: `BGTaskScheduler`, `BGAppRefreshTaskRequest`, `BGContinuedProcessingTaskRequest`, "Choosing Background Strategies for Your App"
- UserNotifications: "Pushing background updates to your App"
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) 2.5.4
- [Use Low Power Mode](https://support.apple.com/en-us/101604); [Shortcuts User Guide: Setting triggers](https://support.apple.com/guide/shortcuts/apde31e9638b/ios)
- Legacy: [App Programming Guide for iOS: Strategies for Handling App State Transitions](https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/StrategiesforHandlingAppStateTransitions/StrategiesforHandlingAppStateTransitions.html)

WWDC: [WWDC15 713 Introducing Watch Connectivity](https://developer.apple.com/videos/play/wwdc2015/713/); [WWDC20 10049 Keep your complications up to date](https://developer.apple.com/videos/play/wwdc2020/10049/); [WWDC21 10048 Principles of great widgets](https://developer.apple.com/videos/play/wwdc2021/10048/); [WWDC25 278 What's new in widgets](https://developer.apple.com/videos/play/wwdc2025/278/)

Apple Developer Forums (Apple engineer replies): [685525](https://developer.apple.com/forums/thread/685525) (Quinn, iOS Background Execution Limits); [759389](https://developer.apple.com/forums/thread/759389); [743829](https://developer.apple.com/forums/thread/743829); [789024](https://developer.apple.com/forums/thread/789024); [745581](https://developer.apple.com/forums/thread/745581); [735352](https://developer.apple.com/forums/thread/735352); [766559](https://developer.apple.com/forums/thread/766559); [819899](https://developer.apple.com/forums/thread/819899); [788911](https://developer.apple.com/forums/thread/788911)

Third party: [BatteryPhone on the App Store](https://apps.apple.com/us/app/batteryphone/id1191334332); [Juice Watch](https://juicewatch.app/)
