# Elephant & Goldfish — Math Challenge project-wide coordination

Status: **proposed governance integration / draft only**. This directory is not proof that Google's EGM plugin is installed, that independent reviewers have run, or that any product change is authorized.

## Purpose
Stop context loss, repeated work, unsupported assumptions, and unreviewed cross-feature drift across the **whole Flutter game**. This is **project-process governance**, not a GameBrain gameplay subsystem. It grants no new data collection or runtime authority.

## Read order for any agent/session
1. Root [AGENTS.md](../../AGENTS.md), [behavior contracts](../behavior_contracts.md), and [refactor tracker](../refactor_tracker.md) (existing rules take precedence).
2. [Project memory](PROJECT_MEMORY.md): scope map and canonical links.
3. [Work register](WORK_REGISTER.md): verified active/completed/pending work.
4. Feature-specific contracts, live code, PR state, and test evidence.
5. [Workflow](WORKFLOW.md): Elephant design, fresh Goldfish review, bounded execution, closure.

Do **not** treat this summary as a substitute for original source, commit, or current CI results.

## Roles
- **Elephant:** read current authoritative sources; reconcile decisions and statuses with evidence; draft a bounded specification; list exclusions, risks and open questions. Never silently turn an assumption into a decision.
- **Goldfish:** separate fresh-context reviewer sees only the spec and explicitly referenced materials (not the prior discussion); challenges gaps, cross-feature impacts, parity, failure modes and verifiability. If fresh subagents are unavailable, record `INDEPENDENT_REVIEW_UNAVAILABLE`; do not claim a Goldfish review occurred.
- **Owner:** approves product choices, tradeoffs, scope, commits/PRs and merges under existing AGENTS.md authorization.
- **Implementer:** only implements approved bounded scope; existing parity_reasoner/flutter_worker/regression_reviewer governance remains intact.

## Global operating principles
- One task identifier; one owner-approved scope; one current status with evidence.
- Check existing PRs and tracker before new work. Prefer continue / reuse / close duplicate over starting from scratch.
- Separate fact, proposal, decision, authorized execution, implementation, verification, and release.
- Keep `main` and a draft PR distinguishable. A CI pass is not device acceptance or release authority.
- Never copy credentials, user records, sensitive logs or opaque private conversation data into memory files.
- Keep this layer small: link to canonical docs rather than duplicating every contract.
- Updating the ledger is a **manual, auditable action**; the files cannot remember work automatically.
- EGM plugin installation is separate and optional. For the official instructions: https://github.com/google/elephant-goldfish-model

## Adoption sequence
1. Bootstrap and inventory; document conflicts as UNKNOWN until verified.
2. Fresh-context review of this process and its actual repository references.
3. Owner approves any process change; merge separately.
4. For each new task, write a scope/spec, review independently, implement, validate, and record outcome.
5. Periodic repository/ledger drift audit; reconcile only with evidence.
