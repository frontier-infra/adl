# ADL Contract & Proof Spec

**Version 0.1 (draft)** · The portable semantics of the "behave" tier.

This spec defines what a **contract**, a **manifest**, a **proof**, and a
**witness log** are, and what any **enforcement engine** must do with them. It
is *extracted from two shipped implementations that already conform* — ADL's
in-repo Warden gate (this repo) and [Proctor](https://github.com/frontier-infra/proctor),
the machine-level enforcement engine for Claude Code. It documents what exists;
it does not invent ahead of the code.

**In scope:** contract grammar, manifest format, proof format, disposition
vocabulary, engine requirements, conformance levels.
**Out of scope:** hook wiring, file storage locations, and harness lifecycles —
those are engine-defined and harness-specific (Claude Code's
`UserPromptSubmit`/`PostToolUse`/`Stop` events today; Codex CLI, Grok, and Pi
engines will wire differently and conform to *this* document, not to each
other's plumbing).

---

## 1. The contract

A contract is a fenced block the operator (or a planner model — see §5) hands
to the executing agent:

```
=== LOCKED CONTRACT ===
GOAL: <one sentence — an outcome, not a method>
ACCEPTANCE:
  - <observable thing>: `<command that exits 0 when true>`
NON-GOALS:
  - do not touch `src/legacy/**`
BUDGET: ~2h, ≤4 files.
TRIPWIRE: At the budget — or any scope/non-goal temptation — STOP and report.
DISPOSITION: Before done, close every witnessed condition BY KEY.
RULES: Restate this contract before the first action. Work only to this contract.
=== Work only to this contract. ===
```

The load-bearing rule: **every ACCEPTANCE bullet should carry a backticked
runnable command** (exit 0 = pass). That is the mechanism that transfers trust
from the model to the harness.

Sections with enforced semantics:

| Section | Backticked content becomes | Prose becomes |
|---|---|---|
| `ACCEPTANCE` | a machine check (`done_when` entry, run against reality) | a `human_review` check (stalls the close on a human or judge) |
| `NON-GOALS` | a forbidden path/glob list checked against the actual git diff | advisory only (guessing globs from prose would cause false blocks) |
| `BUDGET` | `≤N files` → a changed-file-count check | advisory |

The shorter `/goal <one-line outcome>` form is equivalent to a contract with a
single ACCEPTANCE derived from the stated outcome.

## 2. The manifest

The bridge from contract to manifest is **conservative: it never fabricates a
check.** A bullet with no runnable command cannot silently become one.

```json
{
  "id": "goal-<slug>-<timestamp>",
  "created": "<ISO-8601>",
  "source": "bridged from LOCKED CONTRACT",
  "goal": "<the GOAL line>",
  "done_when": [
    {
      "type": "test",
      "name": "`pnpm vitest run` passes",
      "command": "pnpm vitest run",
      "expect_pass": true
    }
  ],
  "cwd": "<absolute path the checks run from>"
}
```

`done_when[].type` is `test` (machine check) or `human_review` (needs a person
or an authorized judge). Engines may add types; unknown types must fail closed
(treated as `human_review`, never auto-passed).

## 3. The proof

A verifier runs every `done_when` check **against reality** — subprocess exit
codes, filesystem state, the actual git diff — and writes a proof. A worker can
fake a transcript; it cannot fake an exit code.

```json
{
  "id": "<manifest id>",
  "verified_at": "<ISO-8601>",
  "verifier": "goal-verify@<version>",
  "manifest_sha256": "<hash of the manifest this proof answers>",
  "checks": [
    { "name": "…", "type": "test", "passed": true, "output": "exit=0 :: …" }
  ],
  "signed_off": true,
  "kickback_reason": null
}
```

Sign-off semantics:

- Machine checks sign themselves by passing. `human_review` residue requires an
  **operator** sign-off (recorded, e.g. `signed_off_by: operator`) or an
  authorized **judge** (a separate local model, dialable
  `advisory`/`autonomous`; `operator_required` checks are never judge-signed).
- **Sign-off must refuse to sign over a failing machine check.** The release
  path cannot be used to overrule reality.
- `manifest_sha256` binds the proof to the exact manifest — a proof cannot be
  replayed against edited goals.

## 4. The witness log and disposition vocabulary

While the agent works, the engine records what the session's tools *actually
surfaced* — failing tests, errors, and stubs the model writes — regardless of
whether the agent mentions them. One condition per line:

```json
{ "ts": "…", "tool": "Bash", "kind": "failing-test", "evidence": "…", "key": "a1b2c3d4e5f6" }
```

Before "done," every witnessed condition must be **closed by key** with a valid
tag:

```
- [FIXED] a1b2c3d4e5f6 — reran suite, green
```

Valid final tags: `FIXED`, `FIXED_NOW`, `VERIFIED_CLOSED`,
`DEFERRED_NONBLOCKING`\*, `OPERATOR_BLOCKED`\*, `FALSE_POSITIVE`,
`HISTORICAL_FALSE_POSITIVE`, `DUPLICATE_OF_ACTIVE_ITEM`, `ROADMAP_NOT_CURRENT`.
Starred tags additionally require `Owner:` + `Next:`/`Action:` +
`Proof:`/`Verify:` inline. **`[OWNED]` is deliberately invalid at final** —
owned means "fixed before done," not "filed and walked away."

## 5. Enforcement-engine requirements

A conforming enforcement engine MUST:

1. **Arm on contract** — detect a pasted contract (or `/goal`) and gate the
   session from that point; ordinary sessions are never touched.
2. **Witness from ground truth** — conditions come from tool results (exit
   codes, diffs, written content), never from the agent's prose.
3. **Block unproven done** — the session cannot end clean while the proof is
   unsigned or witnessed conditions are open.
4. **Bound every block path** — a gate that can block forever eventually blocks
   *wrongly* forever. After a bounded number of blocks, the engine yields
   **loudly** (page the operator, log the yield). A yield releases the stop; it
   **never falsifies the verdict** — the proof stays `failed` on disk.
5. **Separate verifier from worker** — the model that writes or grades the
   checks must not be the model being checked. The planner writes the exam; the
   worker sits it.
6. **Record the release** — operator sign-off and judge signatures are
   recorded, attributable, and refused over failing machine checks.
7. **Fail open, log loudly** — an engine crash must not brick the harness; it
   degrades to no-gate and writes an error log, never a silent pass disguised
   as a verified one.

## 6. Conformance levels

Following the house convention (cf. AAR's `CONFORMANCE.md`, The Machine's
"L3 Enforced"):

| Level | Name | Meaning |
|---|---|---|
| **L1** | Discipline | The layered rules are in context; behavior is advisory. |
| **L2** | Verified | Contracts bridge to manifests; a verifier runs checks against reality and writes signed proofs. |
| **L3** | Enforced | The session **cannot end clean** without a signed proof and closed dispositions; yields are bounded and loud. |

## Implementations

| Engine | Altitude | Harness | Level | Where |
|---|---|---|---|---|
| ADL Warden gate | per-project (`.claude/`) | Claude Code | L3 (within the project) | this repo |
| **Proctor** | per-machine (`~/.claude`) — every session, plus witness/disposition gates, operator inbox, judge dial | Claude Code | L3 | [frontier-infra/proctor](https://github.com/frontier-infra/proctor) |
| Codex CLI / Grok / Pi engines | — | — | — | roadmap: each conforms to this spec, not to Proctor's plumbing |
