# Target Clash UI V5 presentation amendment

Status: APPROVED PRESENTATION AMENDMENT

## Scope

This amends only the unanswered visual layout in TC-03 section 8. The former
vertical presentation (`TARGET`, then expression, then controls) is superseded
by an inline comparison presentation:

```text
7 + 5   [?]   12
```

`[?]` is a visually distinct unknown **relation** marker. It does not mean
that the mathematical result is absent. Before the canonical Clash Reveal, the
expression value remains hidden exactly as required by TC-03.

## Retained authority

All TC-03 gameplay and reveal semantics remain authoritative, including typed
`MathFact` rendering, the fixed `<`, `=`, `>` answer order, canonical
`GameState.onTargetClashAnswer(...)` dispatch, phase projections, the 1300 ms
reveal lifecycle, scoring, Fever, Boss, Power Shot, persistence, and
GameBrain/service firewalls. This amendment authorizes no change to those
behaviors.

## V5.1 visual polish

The standalone `TARGET n` heading is intentionally absent. The target remains
the right-hand operand of the inline relation, so the open prompt has one
mathematical focal point rather than a duplicate target label. Boss Health and
Fever are visually prioritized only when their canonical runtime values are
present; Boss Health remains the current authoritative value and Fever remains
the canonical remaining count. No maximum, percentage, or derived progress is
displayed.
