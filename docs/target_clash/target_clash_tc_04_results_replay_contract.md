# TC-04 Target Clash results, replay, and service compatibility contract candidate R1

Status: corrected candidate for owner approval. This authorizes no source
implementation until approved. It supersedes only the two R1 findings in the
original TC-04 candidate; every other TC-04 decision is retained.

## Authority and retained boundaries

| Classification | Content |
|---|---|
| FROZEN FROM TC-00/01/02/03 | `GameRunType.targetClash`; `GameMode.standard` carrier only; finite runtime; domain owns progression/scoring; GameState owns timers/navigation; no Target Clash High Score/Hall of Fame/economy/cloud/achievements/GameBrain/P1; finished-only completed-game cadence; technical failure is safe non-success terminal. |
| SOURCE-DERIVED CURRENT MAIN | canonical runtime metrics; immutable Target Clash snapshot/config; `_endTargetClash` uses cadence only for `finished`; ordinary `_endGame` leaks forbidden ordinary effects; `replayGame()`/`quitToMenu()` currently recognize only `GameModal.win` for result-dismissal ads. |
| NEW TC-04 CONTRACT DECISION | immutable summary, dedicated results presentation, summary lifetime, display accuracy rounding, fresh replay lifecycle, and the two corrected R1 rules below. |
| OWNER DECISION REQUIRED | none. |

## Successful and technical-failure boundaries

A successful completion is only canonical `TargetClashPhase.finished`, after
the third Final Target resolution and its full 1300 ms reveal. At reveal
expiry, GameState freezes one immutable result summary, records the authorized
completed-game ad cadence exactly once, then presents dedicated results.

`TargetClashPhase.technicalFailure` is non-successful. It creates no summary,
does not record cadence, and invokes no persistence/economy/GameBrain path.
It has no SUCCESSFUL RESULTS actions; it retains only the existing BACK TO MENU
safe-terminal action.

## Immutable summary and metrics

GameState owns nullable immutable Target Clash result-summary state. It freezes
once from the successful terminal runtime and is read-only to presentation.
It is cleared on fresh/replay Target Clash start, valid result dismissal,
quit, invalid snapshot rejection, technical failure, and any transition that
could otherwise expose stale Target Clash history.

The summary contains only result truth:

```text
score                     = runtime.score
correct                   = runtime.correctCount
resolved                  = runtime.resolvedCount
bestCombo                 = runtime.bestCombo
perfectHits               = runtime.perfectHits
bossesDefeated            = runtime.bossesDefeated
finalTargetCompleted      = runtime.finalResolved == 3
finalTargetCleared        = runtime.finalCorrect >= 2
tripleClashesCompleted    = runtime.tripleClashesCompleted
```

Accuracy is derived as `resolved == 0 ? 0 : correct * 100 / resolved`; retain
integer numerator/denominator and display the rounded percentage. Configuration
is composed from the immutable snapshot, not duplicated: operation, difficulty,
number type, and question target. Perfect hits, bosses, Final semantics, and
Triple completion are exactly their canonical runtime truths; no PlayerState
or score inference is permitted.

## R1-01: Replay and Triple selection (corrected)

REPLAY requires a valid frozen successful Target Clash result and retained
valid Target Clash snapshot. It preserves only immutable config and starts a
fresh runtime with fresh timers, reveal identities, question state, score,
combo, Clash Power, Fever/Boss/Final state, and no active historical summary.

No Triple seed, permutation, or sequence is persisted or carried through
Replay. When the fresh runtime later reaches Triple, it performs the canonical
fresh RNG selection (`nextInt(6)` equivalent) again. Its permutation may
coincidentally equal the prior run's permutation. Tests must prove a fresh
selection/no prior-state reuse, never inequality of numeric permutations.

## R1-02: successful result dismissal and interstitial (corrected)

The dedicated Target Clash Results surface is not `GameModal.win`. A valid
frozen successful Target Clash result therefore qualifies as a completed-result
dismissal for REPLAY or BACK TO MENU, in addition to existing ordinary
`GameModal.win` behavior.

For either successful Target Clash result action, GameState must:

1. identify a valid frozen successful Target Clash result dismissal;
2. ensure gameplay is inactive;
3. await existing `_showPendingInterstitialAd()` before replay starts or menu
   navigation completes;
4. never call `_recordCompletedGameForAds()` again;
5. then clear result state and execute replay/navigation.

This reuses the existing pending-ad state, readiness, failure handling,
`adsRemoved` treatment, and cadence. It creates no Target Clash ad policy or
service. A cadence-ineligible result has no pending ad and attempts no
interstitial. No interstitial appears during a question. Technical failure has
no valid successful summary and cannot enter the dismissal path. Ordinary
`GameModal.win` dismissal ordering and behavior remain unchanged.

## Service firewall

Only genuine success calls `_recordCompletedGameForAds()` once. Target Clash
must not call ordinary `_endGame()` and must not mutate games played, cloud
dirty/save, High Score/Hall of Fame, achievements/Play Games, skill mastery or
adaptive state, Operation Quest, Daily Mental Math, coins/shop/IAP, generic
Target Clash storage, GameBrain/QEO/context evidence, P1, telemetry, or cloud
fields. Technical failure receives none of these effects, including cadence.

## Results UI

Use a dedicated Target Clash presentation widget within the existing Target
Clash GameScreen branch, not an ordinary modal. A successful frozen summary
shows only approved canonical metrics and immutable configuration plus REPLAY
and BACK TO MENU. Exclude ordinary score tables, Hall of Fame/high-score copy,
coins, achievements, mastery/intelligence/ability/cognitive labels, and
ordinary mode copy. Keep SafeArea, scroll/constrained layout, visible labeled
actions, semantic action labels, and compact/landscape non-overflow coverage.

## Required focused tests

1. Easy, Medium, and Hard genuine-completion summaries.
2. Exact frozen score, correct/resolved, accuracy formula/rounding/zero guard,
   best combo, perfect hits, bosses, Final completed versus cleared, and
   canonical-only Triple completion.
3. Wrong and timeout Final Target paths; immutable summary after freeze.
4. Replay retains config, creates a new runtime identity, and resets all
   Target Clash transient state.
5. Replay performs a fresh Triple permutation RNG selection and carries no
   prior permutation state. Do not assert that orders differ.
6. Back to Menu clears Target Clash active state and summary.
7. Success increments only the authorized ad cadence; technical failure does
   not; no High Score, achievements, coins, cloud, mastery/adaptive,
   GameBrain, or P1 effects occur.
8. A cadence-eligible successful result REPLAY consumes a pending interstitial
   exactly once, and a blocking ready interstitial completes before replay
   begins.
9. A cadence-eligible successful result BACK TO MENU consumes a pending
   interstitial exactly once; neither action increments `adGameCount` again.
10. Cadence-ineligible success attempts no interstitial; technical failure
    attempts no result-dismissal interstitial; ordinary result dismissal stays
    unchanged.
11. Ordinary Standard, Operation Quest, and Mental Math results/replay remain
    unchanged.
12. Dedicated results UI shows canonical metrics, configuration, and only
    REPLAY/BACK TO MENU; ordinary result-only content is absent.

Use reachable domain/debug seams. Do not manufacture impossible UI states.

## Narrow implementation scope and closure

Candidate production files remain `lib/engine/game_state.dart`,
`lib/screens/game_screen.dart`, and a new
`lib/features/target_clash/presentation/target_clash_results.dart`; add a
domain summary type only if it remains pure and narrow. Candidate focused tests
remain results/replay and results-UI files. No schema, migration, GameMode,
GameBrain, service, economy, or broad modal refactor is authorized.

Before closure: focused and retained Target Clash tests, relevant ordinary
results/replay/ad/persistence regressions, full non-golden suite, visual suite,
analyzer, diff check, scope review, and independent review.

OWNER_DECISIONS_REQUIRED = 0
REPOSITORY_MUTATION = NONE
