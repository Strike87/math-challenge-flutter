# GBR Accelerated Batch 01 — Android acceptance (PENDING)
Owner-approved preparation/build; owner-supplied Goldfish PASS. Baseline fdbbfc63e9e2f1c095512db2337ce5bbfa150f31; candidate feadfb059b0892846b06ecfd42d38f55d2cde290. PR #126 remains Draft. This new verification branch authorizes only workflow, build helper and checklist. Stable A 46040044238/15220595002 retained as reproducible evidence, not golden authority; diagnostic 46046333717/15221734198 and rejected C 46050195005/15224232183 retained. No further font experiments or source/committed golden changes.
## Isolation and local build
Separate exact Git archives, fresh caches, fresh debug-only signing keys, distinct packages com.mohamedk.mathchallenge.gbrbaseline and com.mohamedk.mathchallenge.gbrcandidate, explicit TEST labels, no backup, forbidden network/billing/advertising permissions checked absent in final manifest. Scratch packaging only: test AdMob application ID, empty ad unit defines, dummy PGS ID. Verify final signature and hashes; if a guard fails, stop and remove partial pair. Production Dart, font/golden inventory and dependency lock unchanged. No installation/deployment/Play upload or APK upload; CI retains metadata/logs/public test cert only, discards APKs. Local build retains APKs on the user's computer. Use exact local hashes, not CI hashes, for device observations.
Prerequisites: Git, Python 3.10+, Flutter 3.47.5 exact framework/engine, JDK 17, SDK 36, build-tools 36.0.0, NDK 28.2.13676358, valid licenses, ANDROID_HOME or ANDROID_SDK_ROOT. PowerShell, fresh directory outside production repository:
```powershell
git clone --branch verify/gbr-android-batch01 https://github.com/Strike87/math-challenge-flutter.git GBR-Android-Batch01
cd GBR-Android-Batch01
py -3 tools/verification/gbr_android_build.py --out "$PWD/device-build" --keep-local-apks
```
Do not install until both local builds verify. Use dedicated physical device/profile with no production accounts, airplane mode and Wi-Fi off. Never connect PGS, purchase/restore, use real ads, reset/sync cloud or overwrite/clear production package. No automatic install. Separate app sandbox and denied permissions do not guarantee isolation of other Google services; offline/no-account device is mandatory. If startup fails, report blocker, don't weaken isolation.
## Single device report
Record device model, Android version/build, resolution/density, locale, orientation, font/display scale, theme, renderer/backend (unknown explicitly), accessibility/motion/performance settings, app version, source SHA, local APK hash, signing cert hash, package, reviewer/date. Capture matching original PNG screenshots and hashes, exact reproduction steps, observations and intended/regression/unresolved classification. Test normal and 200% text scale where supported, portrait/landscape, applicable light/dark. Report actual coverage/missing cases.
| Case | Review | Status |
| --- | --- | --- |
| Stage Cleared (10_win_modal) | Same stage/reward; complete title, body, reachable actions | PENDING |
| Ordinary cloud conflict light | Matching synthetic conflict; both options, close | BLOCKED until safe fixture reached |
| Ordinary cloud conflict dark | Matching synthetic conflict; readable options | BLOCKED until safe fixture reached |
| Native cloud conflict light | Separate native choice presentation, not ordinary | BLOCKED until safe fixture reached |
| Emoji | Training Arena rocket, reward/coin, trophy, brain/lightning where visible | PENDING |
| Typography and Material Icons | Labels, numbers, operators, glyph clipping | PENDING |
| Modal accessibility | Adult Gate keyboard without purchase, focus, safe areas, scrolling, reachable controls, theme/text scale | PENDING |
Each row requires baseline/candidate observations and screenshot hashes. Cloud scenarios need safe synthetic fixture; no new injection route in these ordinary offline APKs. Separate scope authorization required if inaccessible; no real account conflicts or native-service evidence inferred from synthetic UI. Physical device NOT VALIDATED. Owner visual acceptance PENDING. All four scene classifications UNRESOLVED. Golden replacement, merge, deployment and release separately authorized and independently reviewed.

## Sequential low-disk build update — owner approved
Windows local attempt: baseline verified; candidate failed with "There is not enough space on the disk" on C: during mergeDebugNativeLibs, and scratch cleanup also failed (WinError 145). Neither was an app logic failure or a completed device-test pair. CI run 46055421909 previously verified both builds and full cleanup; this update preserves every signing, source, permission, dependency and golden guard. Each SHA now gets a fresh separate scratch root, caches and child temp directory; its scratch root must be deleted before the next starts. Staged local APKs are held in pending-apks, verified again as a pair, then renamed to apks only after both builds and cleanups pass; failure invalidates the batch and attempts removal, with any cleanup failure recorded. Console logs stream to terminal and evidence files. Windows long-path cleanup applies only to script-owned directories. Minimum free scratch space before each build is 20 GiB on Windows / 8 GiB on Linux; local output also requires 2 GiB. These are conservative preflight thresholds, not a guaranteed upper bound. No global cache cleanup, no modification of primary SDK, no shared dependency cache.
On the existing Windows checkout, use:
```powershell
git pull --ff-only
$env:Path = "D:\FlutterProjects\flutter-3.47.5\bin;$env:Path"
py -3 tools/verification/gbr_android_build.py --out "$PWD/device-build-v3" --scratch-dir D:\GBR_TEMP --keep-local-apks
```
If either stage fails, report the live log, blocker.json and cleanup.json; do not install from pending-apks or incomplete builds. A new clean output directory is required for retries. No Android device acceptance or merge asserted.
