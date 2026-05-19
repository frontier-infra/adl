---
description: Open a /goal contract — write a verifiable manifest before dispatching work
argument-hint: <one-line description of what done looks like>
---

Open a new `/goal` contract. The manifest you write becomes the binding success criterion for whatever work follows. Workers cannot report done until Warden verifies against this manifest and writes a sign-off proof.

## What to do

1. **Pick a task-id.** Format: `YYYYMMDD-<slug>-<4hex>`. Slug is 2-5 words from the goal, kebab-case. Hex is 4 random characters to disambiguate.

2. **Resolve the role and project.** Based on the goal text and `.claude/orchestrator/ARGENT.md` routing rules, decide which role (`forge` / `quill` / `scout`) will execute the slice and which project overlay applies. If either is unclear, ask the operator. Do not guess.

3. **Translate the goal into machine checks.** For each thing the operator implied, write one `done_when` entry. Prefer `test` and `command` checks. Fall back to `file_exists` / `file_contains` for documentation slices. Use `human_review` only when the goal is genuinely subjective (Scout findings, design decisions) — and then state explicitly what the reviewer should confirm.

4. **Add diff constraints when scope matters.** If the operator named specific files, populate `diff_constraint.touches_only`. If files must not be touched (auth, billing, schema migrations are common), populate `forbidden`. Skip both for documentation-only slices.

5. **Write the manifest** to `.claude/goals/<task-id>.yaml`. Create the directory if it does not exist.

6. **Surface the manifest** back to the operator before dispatching anything. If a `done_when` check is fuzzy ("works correctly," "is fast enough"), say so and ask the operator to tighten it. A vague manifest is worse than no manifest — it gives Warden license to rubber-stamp.

## Manifest schema

```yaml
id: <task-id>
created: <ISO-8601>
operator: <operator name or '@me'>
slice: <one-line description>
role: forge | quill | scout
project: <PROJECT_*.md or 'none'>
base_ref: <git ref to diff against, default: HEAD>
goal: <imperative sentence — what 'done' looks like>
done_when:
  - name: <human-readable check name>
    type: test | command | file_exists | file_contains | diff_constraint | human_review
    # type-specific fields below
    # test:
    command: <test-runner command>
    expect_pass: true
    # command:
    command: <shell command>
    expect_exit: 0
    # file_exists:
    path: <path>
    # file_contains:
    path: <path>
    pattern: <regex or literal>
    # diff_constraint:
    touches_only: [<glob>, ...]
    forbidden: [<glob>, ...]
    # human_review:
    description: <what the reviewer is confirming>
constraints:  # optional — non-negotiable rules carried from project overlay
  - <one-liner>
```

## Anti-patterns

- **One done_when entry that says "it works."** That is not verifiable. Decompose into specific checks or refuse to write the manifest.
- **Manifest for a slice the operator hasn't agreed to.** `/goal` is the contract, not a proposal. If the slice itself is uncertain, route through Quill first to write a spec.
- **Manifest without a role.** Every manifest names exactly one role. Multi-role work means multiple manifests, one per slice.
- **Skipping diff_constraint on code-changing slices.** Even when files are obvious, write it down. The constraint is what catches scope creep.

## Operator input

The operator-supplied goal text follows. Treat it as the source of truth for what they want; ask before adding anything they did not say.

$ARGUMENTS
