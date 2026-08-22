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
| F2 conflict retry | `retryConflict` returned `failedClosed` and the durable snapshot stayed unchanged. | PROVEN |
| F2 gap retry | `retryGap` returned `failedClosed` and the durable snapshot stayed unchanged. | PROVEN |
| Clean close | A fresh ordinary run reached `CLEANLY_CLOSED` with `lastAdmittedOrdinal == lastReconciledOrdinal == 10`, `hasIntegrityDefect = false`, and `hasCleanClosureSignal = true`. After force-stop and direct relaunch, the retained row was still `CLEANLY_CLOSED`. | PROVEN |
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

Fresh live-window F1/F2 evidence:

```json
[
  {
    "command": "readCurrent",
    "payload": {
      "snapshot": {
        "integrityVersion": 1,
        "localWindowSequence": 1,
        "status": "OPEN",
        "admittedORawCount": 2,
        "lastAdmittedOrdinal": 2,
        "lastLegalSetCode": "V1_EMH_MASK_7",
        "lastReconciledOrdinal": 1,
        "hasIntegrityDefect": false,
        "hasCleanClosureSignal": false,
        "legalSetCounters": {"V1_EMH_MASK_7": 2}
      }
    }
  },
  {"command": "retryExact", "payload": {"result": "alreadyAdmitted"}},
  {
    "command": "readCurrent",
    "payload": {
      "snapshot": {
        "integrityVersion": 1,
        "localWindowSequence": 1,
        "status": "OPEN",
        "admittedORawCount": 2,
        "lastAdmittedOrdinal": 2,
        "lastLegalSetCode": "V1_EMH_MASK_7",
        "lastReconciledOrdinal": 1,
        "hasIntegrityDefect": false,
        "hasCleanClosureSignal": false,
        "legalSetCounters": {"V1_EMH_MASK_7": 2}
      }
    }
  },
  {"command": "retryConflict", "payload": {"result": "failedClosed"}},
  {
    "command": "readCurrent",
    "payload": {
      "snapshot": {
        "integrityVersion": 1,
        "localWindowSequence": 1,
        "status": "LEFT_UNCLEAN",
        "admittedORawCount": 2,
        "lastAdmittedOrdinal": 2,
        "lastLegalSetCode": "V1_EMH_MASK_7",
        "lastReconciledOrdinal": 1,
        "hasIntegrityDefect": true,
        "hasCleanClosureSignal": false,
        "legalSetCounters": {"V1_EMH_MASK_7": 2}
      }
    }
  }
]
```

Separate F2 gap evidence:

```json
[
  {
    "command": "readCurrent",
    "payload": {
      "snapshot": {
        "integrityVersion": 1,
        "localWindowSequence": 1,
        "status": "LEFT_UNCLEAN",
        "admittedORawCount": 2,
        "lastAdmittedOrdinal": 2,
        "lastLegalSetCode": "V1_EMH_MASK_7",
        "lastReconciledOrdinal": 1,
        "hasIntegrityDefect": true,
        "hasCleanClosureSignal": false,
        "legalSetCounters": {"V1_EMH_MASK_7": 2}
      }
    }
  },
  {"command": "retryGap", "payload": {"result": "failedClosed"}},
  {
    "command": "readCurrent",
    "payload": {
      "snapshot": {
        "integrityVersion": 1,
        "localWindowSequence": 1,
        "status": "LEFT_UNCLEAN",
        "admittedORawCount": 2,
        "lastAdmittedOrdinal": 2,
        "lastLegalSetCode": "V1_EMH_MASK_7",
        "lastReconciledOrdinal": 1,
        "hasIntegrityDefect": true,
        "hasCleanClosureSignal": false,
        "legalSetCounters": {"V1_EMH_MASK_7": 2}
      }
    }
  }
]
```

Clean close before direct relaunch:

```json
[
  {
    "command": "readRetained",
    "payload": {
      "snapshots": [
        {
          "integrityVersion": 1,
          "localWindowSequence": 1,
          "status": "CLEANLY_CLOSED",
          "admittedORawCount": 10,
          "lastAdmittedOrdinal": 10,
          "lastLegalSetCode": "V1_EMH_MASK_7",
          "lastReconciledOrdinal": 10,
          "hasIntegrityDefect": false,
          "hasCleanClosureSignal": true,
          "legalSetCounters": {"V1_EMH_MASK_7": 10}
        }
      ]
    }
  },
  {
    "command": "readCurrent",
    "payload": {
      "snapshot": {
        "integrityVersion": 1,
        "localWindowSequence": 1,
        "status": "CLEANLY_CLOSED",
        "admittedORawCount": 10,
        "lastAdmittedOrdinal": 10,
        "lastLegalSetCode": "V1_EMH_MASK_7",
        "lastReconciledOrdinal": 10,
        "hasIntegrityDefect": false,
        "hasCleanClosureSignal": true,
        "legalSetCounters": {"V1_EMH_MASK_7": 10}
      }
    }
  }
]
```

Clean close after force-stop and direct relaunch:

After the host-side `flutter run` session died on force-stop, the exact retained
row was confirmed read-only from the relaunched app sandbox database using:

```powershell
adb -s 15133255B4018901 exec-out run-as com.mohamedk.mathchallenge cat databases/p1_f01_integrity.db > C:\Users\Strik\AppData\Local\Temp\p1f01_integrity_after_relaunch.db
```

Local query result:

```json
{
  "rows": [[1, 1, "CLEANLY_CLOSED", 10, 10, "V1_EMH_MASK_7", 10, 0, 1]],
  "counters": [[1, "V1_EMH_MASK_7", 10]]
}
```

## G / F / E conclusions

- `G_DEVICE_STATUS = PROVEN`
- `F_DEVICE_STATUS = PROVEN`
- `E_DEVICE_STATUS = PARTIAL`

`G` is proven by durable `OPEN -> LEFT_UNCLEAN` recovery, stable repeated
recovery, and durable `CLEANLY_CLOSED` retention after clean relaunch. `F` is
proven because exact, conflicting, and gapped retries all exercised their
expected semantics on device. `E` remains partial because an open-window
interruption was exercised, but exact transaction-boundary timing was not
deterministically controlled.

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

- `K_under = FINITE_BUT_BOUND_NOT_ESTABLISHED`
- `K_over = FINITE_BUT_BOUND_NOT_ESTABLISHED`

## Divergence

Observed facts:

- the pre-kill `OPEN` snapshot (`3 / 2`) and the first recovered
  `LEFT_UNCLEAN` snapshot (`4 / 3`) were not identical
- repeated recovery then stabilized at `4 / 3`
- no integrity defect flag was raised

Conclusion:

- `DIVERGENCE_STATUS = BOUNDED`
- `possible direction = NEITHER_PROVEN`

Exercised device paths supported stable no-op exact retry, fail-closed conflict
and gap retries without inflation, stable repeated `LEFT_UNCLEAN` recovery, and
exact retained `CLEANLY_CLOSED` persistence. Exact mid-admission interruption
timing was still not pinned tightly enough to claim zero boundary divergence for
all possible interruption instants.

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

- outstanding-admission closure attempt
- explicit short and long background/resume scenarios
- deterministic mid-admission interruption timing
