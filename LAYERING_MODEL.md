# Layering Model

How the four layers compose when an agent receives a task.

## The layers

```
Layer 4: Task context        (this specific task, right now)
Layer 3: Project overlay     (.claude/projects/PROJECT_*.md)
Layer 2: Role overlay        (.claude/agents/*.md)
Layer 1: Base CLAUDE.md      (project root)
```

Lower-numbered layers take precedence. Higher layers add constraint, never override.

## Precedence rules

- Base CLAUDE.md cannot be relaxed by any other layer
- Role overlays cannot relax base CLAUDE.md
- Project overlays cannot relax role overlays or base CLAUDE.md
- Task context cannot relax any layer above it

When a higher layer appears to conflict with a lower layer, the lower layer wins and the orchestrator (or you) surfaces the conflict.

## How a single delegation composes

Example: you say "Forge, add an idempotency key to the webhook handler in src/api/stripe.ts."

The agent's context window assembles in order:

1. **CLAUDE.md** is loaded by Claude Code automatically. Agent knows: surgical edits, no scope creep, surface confusion, hold position under challenge.
2. **FORGE.md** is loaded because you named Forge. Agent knows: I am Forge, I implement specs, I do not make architecture decisions, I run tests before reporting done.
3. **PROJECT_WEBAPP.md** is loaded because you named it (or because path-to-project mapping resolved the file path). Agent knows: idempotency keys are required, validation through Zod, schema migrations are forward-only.
4. **Task context** is loaded: "add an idempotency key to the webhook handler in src/api/stripe.ts."

Forge now has the full stack and can begin work.

## How multi-agent decomposition composes

Example: you say "Make the demand letter generator better."

The orchestrator (or you, manually) decomposes:

1. **Scout invocation:**
   - Layers: CLAUDE.md + SCOUT.md + PROJECT_WEBAPP.md + "Investigate the current demand letter generator. Map data flow, dependencies, and known issues."
   - Scout returns: findings with citations.

2. **Quill invocation:**
   - Layers: CLAUDE.md + QUILL.md + PROJECT_WEBAPP.md + Scout findings + "Write a spec for improvements based on these findings."
   - Quill returns: implementable spec.

3. **Operator review.**
   - You review the spec before implementation begins.

4. **Forge invocation:**
   - Layers: CLAUDE.md + FORGE.md + PROJECT_WEBAPP.md + Quill spec + "Implement the spec."
   - Forge returns: implementation with test results.

The operator never sees the intermediate layers. The orchestrator (or you) assembles, delegates, integrates, and reports.

## Conflict examples

### A project overlay tries to permit scope creep

If `PROJECT_X.md` says "Forge may proactively refactor adjacent code," this violates CLAUDE.md section 5 (surgical edits). The base wins. The orchestrator should surface the conflict and not silently allow scope creep.

### A task tries to bypass a non-negotiable rule

If a task says "Push this directly to production without review," and the project overlay says "Operator reviews any change to auth, billing, or schema before merge," the project rule wins. The orchestrator escalates.

### Two role overlays would conflict

Roles do not actually conflict because they apply to different work. If a task somehow ends up routed to two roles with conflicting expectations, that is a routing bug, not a layering conflict. Decompose the task instead.

## Versioning

Each layer file has a `Version:` line at the top. When you edit a layer, bump the version. The orchestrator can surface version mismatches against stored memory.

Versioning matters most for project overlays, which change as the product evolves. Role overlays and base CLAUDE.md should change rarely.

## Adding new layers

If you find yourself wanting a fifth layer, stop. Most real needs are met by:

- A new role overlay (for a new specialist)
- A new project overlay (for a new product)
- A task-level constraint (for a specific invocation)

Adding a permanent fifth layer adds confusion without adding capability.

## Why precedence runs floor-up

The precedence rule (lower wins) is deliberate. The base layer encodes universal coding discipline that should never be optional. Role overlays add specialization without weakening discipline. Project overlays add context without weakening role boundaries. Task context tunes a specific invocation without weakening anything above it.

If precedence ran the other way (task wins, then project, then role, then base), every task could relax the base. The result would be a system where rules apply except when convenient, which is the same as no rules at all.

The current direction means: the user (via task context) can always add a constraint but never remove one. To remove a base constraint, you edit the base file deliberately and check in the change.

## How this differs from a flat CLAUDE.md

A flat CLAUDE.md mixes:

- Universal discipline (how to think about code)
- Role behavior (what you do)
- Project context (what this project values)
- Per-task constraints (what this specific task needs)

When these are conflated, you cannot:

- Reuse universal discipline across projects without copy-paste
- Specialize behavior without rewriting universal rules
- Switch projects without context bleed
- Audit the source of any particular agent decision

Separating layers solves all four problems and adds one rule to remember: lower wins.
