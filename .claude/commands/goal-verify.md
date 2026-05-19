---
description: Run Warden against a /goal manifest and write the proof artifact
argument-hint: <task-id>
---

Verify a `/goal` manifest by running every declared check and writing the proof artifact. This is the only way a worker's slice can be marked done — the Stop hook reads the proof and refuses to unblock the worker until `signed_off: true`.

## What to do

1. **Adopt the Warden role.** Read `.claude/agents/WARDEN.md` and apply its discipline strictly. You are not the worker. You do not patch failures. You do not edit the manifest.

2. **Load the manifest** at `.claude/goals/$ARGUMENTS.yaml`. If the file does not exist, refuse — there is nothing to verify against. Compute its SHA-256 and record it in the proof.

3. **Run each check in declaration order.** Do not short-circuit on failure. Capture exit codes, stdout, stderr, and duration for each.

4. **Compute the diff.** Diff against `manifest.base_ref` (default HEAD's parent). Validate `touches_only` and `forbidden` globs against the actual changed paths. A path outside `touches_only` or matching `forbidden` is a check failure, not a warning.

5. **Apply sign-off rules** per `WARDEN.md`:
   - All machine checks passed, no human-review present → `signed_off: true`
   - Any machine check failed → `signed_off: false`, populate `kickback_reason`
   - All machine checks passed, human-review present → `signed_off: "pending"`, populate `kickback_reason` with the items awaiting operator

6. **Write the proof** to `.claude/goals/$ARGUMENTS.proof.json`. Overwrite any prior proof for the same task-id (re-verification is allowed; the latest proof wins).

7. **Report to the operator** per Warden's handoff protocol: task-id, manifest SHA, per-check results, final `signed_off`, kickback target role if applicable, proof path.

## Refusals

- Manifest missing or unreadable → refuse, surface to operator
- Check `type` not in the schema → refuse, do not invent semantics
- Check command unsafe in a verification context (e.g. `rm -rf`, network mutations) → refuse, surface to operator

## Argument

The task-id to verify follows. It must match an existing manifest filename (without `.yaml`).

$ARGUMENTS
