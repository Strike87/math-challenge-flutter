# P1-F01 Physical Device Integrity Validation

Date: 2026-08-22

Verdict: `P1_F01_DEVICE_INTEGRITY_VALIDATION = PARTIAL_DEVICE_EVIDENCE`

Tested Git SHA: `96e9840354e8bff861b00e75f0208c08cf792654`

Runtime note:

- Production/runtime code remained unchanged from
  `231fe276d4fd95508dffdf47730e256549aa2fca`.
- `96e9840354e8bff861b00e75f0208c08cf792654` added the corrected G1 diagnosis
  record only.

Physical device provenance:

- Serial: `15133255B4018901`
- Model: `Infinix X6725`
- Android: `15 / API 35`
- ABI: `arm64-v8a`
- Package: `com.mohamedk.mathchallenge`

Validation build command:

```powershell
flutter run -d 15133255B4018901 --debug --dart-define=P1_F01_DEVICE_VALIDATION=true
```

Observed runtime connection procedure:

1. Launch the debug build from the tested SHA.
2. Read the authenticated VM-service URI from:

   ```powershell
   adb -s 15133255B4018901 logcat -d -v time -s flutter
   ```

3. Forward a host port to the device-side VM-service port:

   ```powershell
   adb -s 15133255B4018901 forward tcp:63301 tcp:<device-vmservice-port>
   ```

4. Call `ext.mathChallenge.p1F01Integrity` over the authenticated URI.

The probe was only available in a debug build with both `kDebugMode` and
`P1_F01_DEVICE_VALIDATION=true`.

Sanitized probe surface proven on device:

- `readCurrent`
- `readRetained`
- `drain`
- `retryExact`
- `retryConflict`
- `retryGap`

Observed returned fields were limited to the approved metadata:

- `integrityVersion`
- `localWindowSequence`
- `status`
- `admittedORawCount`
- `lastAdmittedOrdinal`
- `lastLegalSetCode`
- `lastReconciledOrdinal`
- `hasIntegrityDefect`
- `hasCleanClosureSignal`
- `legalSetCounters`

Fresh controlled state after `pm clear` and relaunch:

```json
{"command":"drain","payload":{"status":"drained"}}
{"command":"readCurrent","payload":{"snapshot":null}}
{"command":"readRetained","payload":{"snapshots":[]}}
```

Canonical gameplay envelope proven on device before interruption testing:

- age gate set to `18 or older`
- GameBrain preference toggled ON
- gameplay HUD showed `GAMEBRAIN ENABLED`
- `Standard` mode
- single-player
- four visible answer choices on the question screen
- `Adaptive Difficulty` OFF
- `Easy` highlighted

## Scenario evidence

| Scenario | Device evidence | Result |
| --- | --- | --- |
| Probe round-trip | Extension commands responded through the authenticated VM-service connection after clean relaunch. | PROVEN |
| G1 OPEN -> force-stop -> relaunch | Pre-kill snapshot was `OPEN`; post-relaunch snapshot was durable `LEFT_UNCLEAN`. | PROVEN |
| G2 repeated recovery | A second force-stop/relaunch preserved the same `LEFT_UNCLEAN` snapshot with no duplicate window or counter inflation. | PROVEN |
| F1 exact retry | On a fresh live `OPEN` window, `retryExact` returned `alreadyAdmitted` and left all counters unchanged. | PROVEN |
| F2 conflict retry | `retryConflict` returned `failedClosed` and the exercised snapshot stayed unchanged. | PARTIAL |
| F2 gap retry | `retryGap` returned `failedClosed` and the exercised snapshot stayed unchanged. | PARTIAL |
| Clean close | The active run reached `CLEANLY_CLOSED` before restart, but its persistence through direct relaunch was not validly verified. | PARTIAL |
| Outstanding admission at closure | Not truthfully exercised on device. | NOT_TRUTHFULLY_EXERCISABLE_ON_DEVICE in this run |
| Admission-boundary interruption | G1 exercised an open-window interruption, but exact mid-admission timing was not deterministically pinned. | `E_TRANSACTION_BOUNDARY = PARTIALLY_EXERCISED` |
| Background / resume | Not completed in a controlled uninterrupted device session. | NOT PROVEN |
| Storage failure | No safe device-side failure injection mechanism was available in the approved probe surface. | `DEVICE_STORAGE_FAILURE = NOT_SAFELY_REPRODUCIBLE` |

## Before / after snapshots

G1 pre-force-stop (`OPEN`):

```json
{"command":"drain","payload":{"status":"drained"}}
{"command":"readCurrent","payload":{"snapshot":{"integrityVersion":1,"localWindowSequence":1,"status":"OPEN","admittedORawCount":3,"lastAdmittedOrdinal":3,"lastLegalSetCode":"V1_EMH_MASK_7","lastReconciledOrdinal":2,"hasIntegrityDefect":false,"hasCleanClosureSignal":false,"legalSetCounters":{"V1_EMH_MASK_7":3}}}}
{"command":"readRetained","payload":{"snapshots":[{"integrityVersion":1,"localWindowSequence":1,"status":"OPEN","admittedORawCount":3,"lastAdmittedOrdinal":3,"lastLegalSetCode":"V1_EMH_MASK_7","lastReconciledOrdinal":2,"hasIntegrityDefect":false,"hasCleanClosureSignal":false,"legalSetCounters":{"V1_EMH_MASK_7":3}}]}}
```

G1 post-relaunch (`LEFT_UNCLEAN`):

```json
{"command":"readRetained","payload":{"snapshots":[{"integrityVersion":1,"localWindowSequence":1,"status":"LEFT_UNCLEAN","admittedORawCount":4,"lastAdmittedOrdinal":4,"lastLegalSetCode":"V1_EMH_MASK_7","lastReconciledOrdinal":3,"hasIntegrityDefect":false,"hasCleanClosureSignal":false,"legalSetCounters":{"V1_EMH_MASK_7":4}}]}}
{"command":"readCurrent","payload":{"snapshot":{"integrityVersion":1,"localWindowSequence":1,"status":"LEFT_UNCLEAN","admittedORawCount":4,"lastAdmittedOrdinal":4,"lastLegalSetCode":"V1_EMH_MASK_7","lastReconciledOrdinal":3,"hasIntegrityDefect":false,"hasCleanClosureSignal":false,"legalSetCounters":{"V1_EMH_MASK_7":4}}}}
```

G2 repeated recovery:

```json
{"command":"readRetained","payload":{"snapshots":[{"integrityVersion":1,"localWindowSequence":1,"status":"LEFT_UNCLEAN","admittedORawCount":4,"lastAdmittedOrdinal":4,"lastLegalSetCode":"V1_EMH_MASK_7","lastReconciledOrdinal":3,"hasIntegrityDefect":false,"hasCleanClosureSignal":false,"legalSetCounters":{"V1_EMH_MASK_7":4}}]}}
{"command":"readCurrent","payload":{"snapshot":{"integrityVersion":1,"localWindowSequence":1,"status":"LEFT_UNCLEAN","admittedORawCount":4,"lastAdmittedOrdinal":4,"lastLegalSetCode":"V1_EMH_MASK_7","lastReconciledOrdinal":3,"hasIntegrityDefect":false,"hasCleanClosureSignal":false,"legalSetCounters":{"V1_EMH_MASK_7":4}}}}
```

F retries on the recovered window:

```json
{"command":"readCurrent","payload":{"snapshot":{"integrityVersion":1,"localWindowSequence":1,"status":"LEFT_UNCLEAN","admittedORawCount":4,"lastAdmittedOrdinal":4,"lastLegalSetCode":"V1_EMH_MASK_7","lastReconciledOrdinal":3,"hasIntegrityDefect":false,"hasCleanClosureSignal":false,"legalSetCounters":{"V1_EMH_MASK_7":4}}}}
{"command":"retryExact","payload":{"result":"failedClosed"}}
{"command":"readCurrent","payload":{"snapshot":{"integrityVersion":1,"localWindowSequence":1,"status":"LEFT_UNCLEAN","admittedORawCount":4,"lastAdmittedOrdinal":4,"lastLegalSetCode":"V1_EMH_MASK_7","lastReconciledOrdinal":3,"hasIntegrityDefect":false,"hasCleanClosureSignal":false,"legalSetCounters":{"V1_EMH_MASK_7":4}}}}
{"command":"retryConflict","payload":{"result":"failedClosed"}}
{"command":"readCurrent","payload":{"snapshot":{"integrityVersion":1,"localWindowSequence":1,"status":"LEFT_UNCLEAN","admittedORawCount":4,"lastAdmittedOrdinal":4,"lastLegalSetCode":"V1_EMH_MASK_7","lastReconciledOrdinal":3,"hasIntegrityDefect":false,"hasCleanClosureSignal":false,"legalSetCounters":{"V1_EMH_MASK_7":4}}}}
{"command":"retryGap","payload":{"result":"failedClosed"}}
{"command":"readCurrent","payload":{"snapshot":{"integrityVersion":1,"localWindowSequence":1,"status":"LEFT_UNCLEAN","admittedORawCount":4,"lastAdmittedOrdinal":4,"lastLegalSetCode":"V1_EMH_MASK_7","lastReconciledOrdinal":3,"hasIntegrityDefect":false,"hasCleanClosureSignal":false,"legalSetCounters":{"V1_EMH_MASK_7":4}}}}
```

## G / F / E conclusions

- `G_DEVICE_STATUS = PROVEN`
- `F_DEVICE_STATUS = PARTIAL`
- `E_DEVICE_STATUS = PARTIAL`

`G` is proven by durable `OPEN -> LEFT_UNCLEAN` recovery and stable repeated
recovery. `F` is partial: exact retry was proven on a fresh `OPEN` window, but
conflict and gap retries were not recreated against a fresh `OPEN` opportunity.
`E` remains partial because an open-window interruption was exercised, but exact
transaction-boundary timing was not deterministically controlled.

## K_under / K_over

Design target:

- bounded finite mis-accounting with fail-closed recovery

Implementation semantics observed:

- recovered windows stayed durable and repeated recovery did not duplicate the
  retained snapshot
- retry hooks failed closed on the exercised recovered state

Device evidence:

- no finite bound was established from this physical run alone

Conclusions:

- `K_under = NOT_PROVEN`
- `K_over = NOT_PROVEN`

## Divergence

Observed facts:

- the pre-kill `OPEN` snapshot (`3 / 2`) and the first recovered
  `LEFT_UNCLEAN` snapshot (`4 / 3`) were not identical
- repeated recovery then stabilized at `4 / 3`
- no integrity defect flag was raised

Conclusion:

- `DIVERGENCE_STATUS = NOT_PROVEN`
- `possible direction = NEITHER_PROVEN`

Exact mid-admission interruption timing was not pinned tightly enough to claim
zero boundary divergence for all possible interruption instants.

## Lifecycle limitation

This physical run exercised run-local recovery behavior only. The future study
evidence evaluator (`O_valid`, common-support gating, confirmatory collection)
is not implemented here, so this run cannot by itself prove whether every
lifecycle-interrupted event would be excluded from future ordinary `O_valid`
study evidence.

## Gameplay firewall

Across the exercised device scenarios:

- difficulty remained canonical
- the question generator remained canonical
- scoring remained canonical
- progression remained canonical
- integrity storage did not authorize gameplay
- recovery did not alter gameplay authority

Final firewall statement:

- `mayAffectGameplay = false`

## Remaining blocker

The remaining blocker to a full device PASS is incomplete physical-scenario
coverage, specifically:

- clean-close persistence through direct relaunch with package identity recorded
- outstanding-admission closure attempt
- explicit short and long background/resume scenarios
- deterministic mid-admission interruption timing

## Continuation after corrected G1

The corrected G1/G2 evidence above remains authoritative: the initial
apparent loss was a relaunch artifact, not an implementation defect.

### F1 exact retry

On a fresh canonical eligible `OPEN` window, the immediate probe sequence was:

```json
{"before":{"admittedORawCount":10,"lastAdmittedOrdinal":10,"lastReconciledOrdinal":9,"legalSetCounters":{"V1_EMH_MASK_7":10},"hasIntegrityDefect":false}}
{"retryExact":{"result":"alreadyAdmitted"}}
{"after":{"admittedORawCount":10,"lastAdmittedOrdinal":10,"lastReconciledOrdinal":9,"legalSetCounters":{"V1_EMH_MASK_7":10},"hasIntegrityDefect":false}}
```

`F1 = PROVEN` for `DEVICE_STORE_SEMANTICS`: no second admission, counter
increment, window creation, or defect was produced.

### F2 retries

`retryConflict` and `retryGap` both returned `failedClosed` and left the
exercised retained snapshot unchanged. The conflict command was exercised
after the canonical run had cleanly closed; the gap command was exercised on
the recovered `LEFT_UNCLEAN` state. Both are safe fail-closed observations,
but neither recreates an invalid retry against a fresh `OPEN` opportunity.

`F2 = PARTIAL` for device semantics.

### Clean-close continuation limitation

The canonical run reached `CLEANLY_CLOSED` with admitted and reconciled
ordinals both `10`. A later direct-relaunch observation returned an earlier
`LEFT_UNCLEAN` snapshot (`2 / 1`). Package identity was not recorded on both
sides of that observation; the current package reports a later
`lastUpdateTime`. Therefore this is not valid clean-close persistence evidence
and is not classified as a store defect.

Required remaining controlled run:

1. record package identity before closure;
2. reach `CLEANLY_CLOSED` and drain;
3. force-stop and direct-launch without package replacement;
4. record package identity again, then attach, drain, and read retained state.

### Remaining conclusions

- `G_DEVICE_STATUS = PROVEN`
- `F_DEVICE_STATUS = PARTIAL`
- `E_DEVICE_STATUS = PARTIAL`
- `K_under = NOT_PROVEN`
- `K_over = NOT_PROVEN`
- `DIVERGENCE_STATUS = NOT_PROVEN`
- `possible direction = NEITHER_PROVEN`
- `OUTSTANDING_ADMISSION_DEVICE = NOT_TRUTHFULLY_EXERCISABLE`
- lifecycle: `PROTOCOL_RULE_SUPPORTED_BUT_STUDY_EVALUATOR_NOT_IMPLEMENTED`
- `DEVICE_STORAGE_FAILURE = NOT_SAFELY_REPRODUCIBLE`
- `mayAffectGameplay = false`

## Remaining-evidence continuation

This continuation supersedes the earlier `F2 = PARTIAL` and clean-close
limitations with new physical-device evidence. It does not supersede the
transaction-boundary limitation.

### Same-install identity and clean close

Before and after the direct no-install restart, package-manager data matched:

- package `com.mohamedk.mathchallenge`, version `1.0.8` / versionCode `37`;
- UID `10260`;
- first install `2026-08-22 16:00:14` and last update `2026-08-22 16:56:57`;
- APK path `/data/app/~~sNCOwxwKvahhBHaakge8xQ==/com.mohamedk.mathchallenge-G4HVCYUY62ePYfGGtS1bOQ==/base.apk`.

`SAME_PACKAGE_INSTALLATION = PROVEN`.

Fresh window `4` reached `CLEANLY_CLOSED` with `O_raw = 10`, admitted ordinal
`10`, reconciled ordinal `10`, counter `V1_EMH_MASK_7 = 10`, and no defect.
After force-stop and direct Android relaunch without reinstall, the approved
probe reported that exact same cleanly closed window and values.

### Fresh F2 and repeated F1

Fresh `OPEN` window `2` had `O_raw = 2`, admitted ordinal `2`, reconciled
ordinal `1`, `V1_EMH_MASK_7 = 2`, and no defect before `retryConflict`.
It returned `failedClosed`; all accounting values stayed `2 / 2 / 1 / 2` and
the window moved fail-closed to `LEFT_UNCLEAN` with a defect marker.

Fresh `OPEN` window `3` had the same accounting baseline before `retryGap`.
It returned `failedClosed` with no accounting inflation and the same
fail-closed `LEFT_UNCLEAN` result.

Fresh `OPEN` window `4` received `retryExact` twice. Both returned
`alreadyAdmitted`; after each call, `O_raw`, admitted ordinal, counter, and
window sequence remained `1`, and no defect was raised.

`F_DEVICE_STATUS = PROVEN` for the exercised device store semantics.

### Admission-boundary trials

The earliest controllable start interruption produced no new retained window:
the retained set remained windows `1` through `4`. This supports the
admission-absent outcome.

The post-admission trial recorded fresh `OPEN` window `5` at `O_raw = 1`,
admitted ordinal `1`, unreconciled ordinal, and counter `1` before force-stop.
After direct no-install relaunch, it recovered as `LEFT_UNCLEAN` with
internally consistent `O_raw = 3`, admitted ordinal `3`, reconciled ordinal
`2`, and counter `3`. No contradictory durable row or counter was observed,
but this device procedure cannot attribute the extra admissions to an exact
transaction-boundary instant.

- `E_DEVICE_STATUS = PARTIAL`
- `E_BLOCKER = DETERMINISTIC_TRANSACTION_BOUNDARY_TESTABILITY`
- `K_under = NOT_PROVEN`
- `K_over = NOT_PROVEN`
- `DIVERGENCE_STATUS = NOT_PROVEN`
- possible direction: `NEITHER_PROVEN`

No production code, gameplay authority, or protocol document changed in this
continuation. `mayAffectGameplay = false` remains true.
