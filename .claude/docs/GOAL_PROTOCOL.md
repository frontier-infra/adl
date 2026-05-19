# Goal Protocol

How the `/goal` contract, the Warden verifier, and the Stop hook compose into a closed verification loop.

This protocol exists because Layer 1 section 6 ("Goal-driven loops") tells every agent to define verifiable success criteria, but does not specify *where* the criteria live, *who* verifies them, or *what* prevents the agent from claiming done without verification. This document is the implementation.

## The loop

```
                 [Operator]
                     │
                     │ /goal "<imperative>"
                     ▼
            .claude/goals/<id>.yaml          (manifest, signed by author)
                     │
                     │ dispatch via Argent
                     ▼
              [Role overlay]                 (Forge / Quill / Scout)
                     │
                     │ produces diff + tests
                     ▼
            /goal-verify <id>
                     │
                     ▼
                  [Warden]                   (.claude/agents/WARDEN.md)
                     │
                     │ runs every done_when check
                     ▼
         .claude/goals/<id>.proof.json       (signed_off: true | false | "pending")
                     │
                     ▼
                 [Stop hook]                 (reads proof, gates the worker)
                     │
                     │ refuses to release done if signed_off ≠ true
                     ▼
                 [Operator]                  (reviews proof + integrates)
```

The worker never sees `signed_off`. The hook does. From the worker's perspective, work is done when Warden says so.

## Manifest schema

Location: `.claude/goals/<task-id>.yaml`

```yaml
id: 20260519-add-idempotency-key-a1b2
created: 2026-05-19T15:23:00Z
operator: '@jason'
slice: Add idempotency key to Stripe webhook handler
role: forge
project: PROJECT_WEBAPP.md
base_ref: HEAD
goal: |
  src/api/stripe.ts persists the Stripe-Event-ID for every received event
  and short-circuits on replay. Existing tests still pass; one new test
  proves the replay short-circuit.
constraints:
  - Schema migrations are forward-only; do not edit existing migration files
done_when:
  - name: replay short-circuit test passes
    type: test
    command: pnpm test src/api/stripe.test.ts -t "replays are short-circuited"
    expect_pass: true
  - name: existing webhook tests still pass
    type: test
    command: pnpm test src/api/stripe.test.ts
    expect_pass: true
  - name: typecheck clean
    type: command
    command: pnpm typecheck
    expect_exit: 0
  - name: only stripe handler + new migration touched
    type: diff_constraint
    touches_only:
      - src/api/stripe.ts
      - src/api/stripe.test.ts
      - prisma/migrations/*_idempotency.sql
    forbidden:
      - prisma/migrations/0*.sql  # no edits to existing migrations
```

### Check types

| Type             | Required fields                       | Passes when                                              |
|------------------|---------------------------------------|----------------------------------------------------------|
| `test`           | `command`, `expect_pass: true`        | Test runner exits 0                                      |
| `command`        | `command`, `expect_exit: <int>`       | Process exit code matches `expect_exit`                  |
| `file_exists`    | `path`                                | `path` is a regular file at verification time            |
| `file_contains`  | `path`, `pattern`                     | `pattern` (regex) matches inside `path`                  |
| `diff_constraint`| `touches_only` and/or `forbidden`     | Every changed path matches `touches_only` and no path matches `forbidden` |
| `human_review`   | `description`                         | Never passes automatically; produces `signed_off: "pending"` |

## Proof artifact

Location: `.claude/goals/<task-id>.proof.json`

Warden overwrites any prior proof for the same task-id. Only the latest verification result counts.

```json
{
  "id": "20260519-add-idempotency-key-a1b2",
  "verified_at": "2026-05-19T15:51:12Z",
  "verifier": "WARDEN@1.0.0",
  "manifest_sha256": "9c0a...3f",
  "checks": [
    {
      "name": "replay short-circuit test passes",
      "type": "test",
      "passed": true,
      "duration_ms": 412,
      "output": "PASS src/api/stripe.test.ts\n  ✓ replays are short-circuited (38 ms)"
    },
    {
      "name": "only stripe handler + new migration touched",
      "type": "diff_constraint",
      "passed": true,
      "duration_ms": 11,
      "output": "changed: src/api/stripe.ts, src/api/stripe.test.ts, prisma/migrations/20260519_idempotency.sql"
    }
  ],
  "diff_summary": {
    "files_changed": ["src/api/stripe.ts", "src/api/stripe.test.ts", "prisma/migrations/20260519_idempotency.sql"],
    "insertions": 47,
    "deletions": 3
  },
  "signed_off": true,
  "kickback_reason": null
}
```

## Sign-off states

| `signed_off` value | Meaning                                                                | Stop hook |
|--------------------|------------------------------------------------------------------------|-----------|
| `true` (bool)      | Every machine check passed; no human-review pending                    | Releases  |
| `false` (bool)     | At least one machine check failed; `kickback_reason` names the failure | Blocks    |
| `"pending"` (str)  | Machine checks passed; one or more `human_review` items await operator | Blocks    |

The operator promotes `"pending"` to `true` manually after reviewing the human-review checklist. There is no automated promotion path. This is deliberate — the whole point of `human_review` is that a human signs.

## Stop-hook contract

The hook fires when a worker tries to terminate (report done). It looks up the active task-id (from session context or an env var, depending on your harness), reads the proof at `.claude/goals/<task-id>.proof.json`, and:

- Proof missing → block. Worker did not run `/goal-verify`.
- `signed_off: true` → release.
- Anything else → block. Worker must either fix the underlying failure and re-verify, or hand off to the operator with the kickback reason.

A reference hook config ships at `.claude/settings.example.json`. The installer also ships `.claude/hooks/goal-gate.sh` as the real executable gate. Copy the settings example into `.claude/settings.json` (or merge into existing), ensure `jq` is installed, and adjust task-id resolution if your harness exposes it differently.

## Kickback routing

When `signed_off: false`, Warden names the failed checks. The operator (or Argent in automated setups) routes the kickback by failure type:

| Failure type                                    | Route to |
|-------------------------------------------------|----------|
| `test` check failed                             | Forge    |
| `command` check failed (build / typecheck / lint) | Forge    |
| `file_exists` / `file_contains` on a doc        | Quill    |
| `diff_constraint` violation                     | Operator (scope drift — decide whether to rewrite the manifest or trim the diff) |
| Manifest references a system that does not exist | Scout (verify the system) → operator (decide) |

Never silently re-dispatch to the role that just failed. The kickback always returns to the operator first unless the route is obvious.

## Re-verification

A worker may re-attempt and re-verify within the same task-id. Warden overwrites the proof. Operators should grep for repeated `signed_off: false` proofs in `.claude/goals/` — three failures on the same manifest means the manifest is wrong, not the worker.

## What `/goal` does not solve

- **Wrong manifest.** If `done_when` does not actually capture the operator's intent, a passing proof is a green check on the wrong thing. The manifest is only as good as the operator's specificity at write time. `/goal` is a contract surface, not a clairvoyance tool.
- **Flaky verifiers.** A test that passes sometimes will produce inconsistent proofs. This is a test quality problem, not a protocol problem. Surface to Forge as a separate slice.
- **Pure research slices.** Scout investigations have no automatable verifier. The `human_review` mode plus operator sign-off is the answer; the audit trail still exists in the proof artifact.

## Integration with Argent

The orchestrator's dispatch contract (see `.claude/orchestrator/ARGENT.md`) requires:

1. Every dispatched slice has a corresponding manifest.
2. The dispatch prompt explicitly references the manifest path so the worker can read its constraints.
3. After the worker reports done, Argent runs `/goal-verify` before integrating the result.
4. Argent surfaces the proof artifact path in the operator-facing report.

This is the mechanism that closes the "generic worker" loophole. A worker without a manifest cannot meet the contract because there is no contract; Argent's refusal to dispatch in that state is what enforces role-typed work.
