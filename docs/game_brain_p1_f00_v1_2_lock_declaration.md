# P1-F00 v1.2 — Lock declaration

## 1. Purpose

This is a small companion governance document. It formally records the
subsequent independent-review decision and the lock state of the P1-F00 v1.2
no-replacement confirmatory envelope amendment, without rewriting history.

It does not rewrite, amend, rebase, or modify commit `c11dd39`, and it does
not edit the historical v1.2 amendment file in place.

## 2. Declaration record

| Field | Value |
| --- | --- |
| Artifact | P1-F00 v1.2 no-replacement confirmatory envelope amendment (`docs/game_brain_p1_f00_v1_2_no_replacement_envelope_amendment.md`) |
| Amendment text commit | `c11dd39f2c10c2460b4cfc54fb2f9c174f81c93c` — "Lock P1-F00 v1.2 no-replacement envelope" |

## 3. Historical fact (preserved, not rewritten)

The amendment file committed at `c11dd39` retained the self-label:

```text
PROSPECTIVE DRAFT / PENDING INDEPENDENT REVIEW
```

That historical self-label stands as recorded. This declaration does not
imply that the `c11dd39` file itself originally contained the locked status.

## 4. Subsequent review decision

```text
INDEPENDENT_REVIEW = APPROVED_FOR_LOCK
```

The independent review evaluated the exact amendment text at `c11dd39` and
returned `APPROVED_FOR_LOCK`.

## 5. Lock declaration

On the basis of that review decision, the exact amendment text at `c11dd39`
is hereby adopted prospectively as:

```text
P1-F00 v1.2 = LOCKED / CURRENT PROSPECTIVE AMENDMENT
```

The lock attaches to the exact text committed at `c11dd39`; no protocol text
is changed by this declaration.

## 6. Effective semantics

P1-F00 v1.1 remains inherited in full except where explicitly superseded by
the exact v1.2 text at `c11dd39`. The v1.2 superseding rule is the
no-replacement confirmatory envelope: replacement-generated questions are
prospectively excluded from the confirmatory-eligible `O_raw` population,
with a synchronous fail-closed admission firewall established before any
replacement question can open, while gameplay continues unchanged.

## 7. Confirmatory window

```text
P1_F01_CONFIRMATORY_WINDOW = CLOSED / NOT OPENED
```

Nothing in this declaration opens, schedules, or authorizes a confirmatory
window.

## 8. Outcome blindness and authority boundary

- No outcome data informed this lock; no real P1-F01 outcome data has been
  inspected.
- No gameplay authority expansion of any kind follows from this declaration.
- `mayAffectGameplay = false` remains true.

## 9. Implementation lineage

Commit `932129e6225f8d55a3769ffae12cf6fdf868b30c` ("Implement P1-F00 v1.2
no-replacement envelope") implements the locked no-replacement envelope.

## 10. Scope of this declaration

This declaration changes governance/status only. It does not modify:

- protocol text;
- production code;
- tests;
- capture scope or retention;
- thresholds;
- evidence records.

Per the standing prospective-only amendment policy, any future scientific
change to v1.2 requires a new prospective, versioned amendment with
independent review where required.
