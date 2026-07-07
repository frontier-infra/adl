# Agent Discipline Layer (ADL)

_Formerly **Claude Layers** — same tool, new name. Claude Code today; Grok, Codex CLI, and Pi on the roadmap._

[![Latest release](https://img.shields.io/github/v/release/frontier-infra/adl?label=release&color=7C3AED)](https://github.com/frontier-infra/adl/releases)
[![License: MIT](https://img.shields.io/github/license/frontier-infra/adl?color=blue)](LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-D97757)](https://claude.com/claude-code)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](CONTRIBUTING.md)

**Keep your Claude Code agent honest — and make it prove its work.**
_The discipline layer of [The Machine](https://frontierinfra.org): layered guardrails for Claude Code, plus a gate that won't let the agent call it "done" until a real check passes._

**The problem.** You ask for a small change. The agent silently rewrites a working file, invents a
requirement you never gave it, folds the instant you push back — and reports "done." You find out later.

**What the Agent Discipline Layer does.** Two things. It stacks **four layers of discipline** into the agent's
context so the rules can't quietly contradict each other (the strongest-worded line stops winning by
accident). And it adds a **verify-against-reality gate**: a `/goal` contract whose checks a separate
verifier (**Warden**) actually runs — a test passes, a file exists, the diff stays in bounds — and
**signs a proof**. "Done" stops meaning *the agent said so* and starts meaning *the checks passed*. A
worker can fake a transcript; it can't fake a failing test.

## Quickstart (~1 minute)

Install into your project:

```bash
curl -fsSL https://raw.githubusercontent.com/frontier-infra/adl/main/install.sh | bash
# or:  git clone https://github.com/frontier-infra/adl.git && ./install.sh /path/to/your/project
```

Confirm the discipline loaded — in your Claude Code session:

```
Read CLAUDE.md, then summarize in three sentences what behaviors it requires.
```

A correct answer mentions **reading before writing, surfacing confusion before acting, and surgical
edits**. If it skips those, the file didn't load.

Then lock a verifiable contract and let Warden sign it off:

```
/goal the replay test in src/api/stripe.test.ts passes and only the stripe handler is touched
        →  writes a manifest of checks; a role (Forge) does the work
/goal-verify
        →  Warden runs the checks against reality and writes a signed proof
```

Wire the Stop-hook gate once (copy `.claude/settings.example.json` into `.claude/settings.json`) and
the session **cannot end until the proof says `signed_off: true`** — so "done" is earned, not asserted.

## What you get

- **Four composing layers** — universal discipline · role (Forge / Quill / Scout / Warden) · project
  values · per-task contract — stacked with clear precedence and **no silent contradictions**.
- **`/goal` + Warden** — a verifiable contract per slice, checked against *reality* and signed, never
  self-assessed.
- **Honest by construction** — the gate blocks done-in-silence; the verifier is never the worker.

> **Shipped today:** the four layers + the `/goal` manifest → Warden → signed proof → Stop-hook gate.
> **Roadmap (marked honestly, not shipped):** an owned local model to sign the subjective residue so
> you're not the default reviewer; a ratified amendment channel; a multi-model council.

## Enforcement engines

ADL's contract/proof semantics are a spec, and this repo ships one engine for
them. The spec is **[specs/adl-contract-and-proof.md](specs/adl-contract-and-proof.md)** —
contract grammar, manifest and proof formats, disposition vocabulary, and what
any conforming engine must do.

| Engine | Altitude | Harness | What it adds |
|---|---|---|---|
| **Warden gate** (this repo) | per-project (`.claude/`) | Claude Code | `/goal` → manifest → verified, signed proof → Stop-hook gate |
| **[Proctor](https://github.com/frontier-infra/proctor)** | per-machine (`~/.claude`) — supervises every session | Claude Code | witness log from tool ground truth, disposition gate, bounded loud yields, operator inbox + recorded sign-off, and the judge dial (a local model signing `human_review` residue — the roadmap item above, shipped there today) |

Same contract, same manifest, same proof — different altitude. Install ADL in
the repo, Proctor on the machine; they compose. The multi-harness roadmap
(Grok, Codex CLI, Pi) means *new engines conforming to the spec*, not ports of
either implementation's plumbing.

The deeper sections below explain the layering model, the roles, and the goal protocol in full.

---

## Why this exists

In late 2025, the bar for what an AI coding agent could do crossed a threshold. Andrej Karpathy summarized the failure modes that remain ([source](https://x.com/karpathy/status/2015883857489522876), [HN discussion](https://news.ycombinator.com/item?id=46771564)):

> They make wrong assumptions on your behalf and just run along with them without checking. They don't manage their confusion, they don't seek clarifications, they don't surface inconsistencies, they don't present tradeoffs, they don't push back when they should, and they are still a little too sycophantic... They also really like to overcomplicate code and APIs, they bloat abstractions, they don't clean up dead code after themselves.

A single `CLAUDE.md` at the root of your project addresses some of this. But a single flat file struggles when:

- You work on multiple projects with different values, vocabularies, and constraints
- You want specialized agents (builder, writer, investigator) with clear ownership boundaries
- You want the agent to know when to escalate to you versus when to act
- You want the same agent to behave differently depending on which project it is in

`adl` solves these by separating concerns into composable layers.

## The layering model

```
Layer 4: Task context        (what you typed, right now)
Layer 3: Project overlay     (.claude/projects/PROJECT_*.md)
Layer 2: Role overlay        (.claude/agents/*.md)
Layer 1: Base CLAUDE.md      (project root)
```

**Lower-numbered layers take precedence.** Higher layers add constraint, never relax it.

Concretely: if your project overlay says "Forge may proactively refactor adjacent code" but the base `CLAUDE.md` says "do not improve adjacent code as a side effect," the base wins. The project overlay is misleading and gets surfaced as a conflict, not silently applied.

This precedence model is the whole point. It means you can write project overlays without worrying about accidentally undermining the universal discipline, and you can write role overlays without worrying about being overridden by overzealous project instructions.

## What gets installed

```
your-project/
├── CLAUDE.md                              # Layer 1: universal discipline
└── .claude/
    ├── agents/
    │   ├── FORGE.md                       # Layer 2: builder role
    │   ├── QUILL.md                       # Layer 2: writer role
    │   ├── SCOUT.md                       # Layer 2: investigator role
    │   └── WARDEN.md                      # Layer 2: verifier role (/goal sign-off)
    ├── commands/
    │   ├── goal.md                        # /goal: open a verifiable contract
    │   └── goal-verify.md                 # /goal-verify: run Warden, sign off
    ├── goals/                             # /goal manifests + Warden proof artifacts
    ├── projects/
    │   ├── PROJECT_TEMPLATE.md            # blank template for new projects
    │   ├── PROJECT_WEBAPP.md              # example: full-stack web app
    │   ├── PROJECT_API.md                 # example: REST/GraphQL service
    │   └── PROJECT_CLI.md                 # example: command-line tool
    ├── orchestrator/
    │   └── ARGENT.md                      # routing and context composition
    ├── docs/
    │   ├── LAYERING_MODEL.md              # how layers compose at runtime
    │   ├── ROUTING_PATTERNS.md            # when to use which agent
    │   ├── CREATING_OVERLAYS.md           # how to write a new overlay
    │   └── GOAL_PROTOCOL.md               # /goal manifest + Warden + Stop hook
    └── settings.example.json              # reference Stop-hook config for /goal gating
```

The example projects (`WEBAPP`, `API`, `CLI`) are reference material. Delete the ones you do not need and copy `PROJECT_TEMPLATE.md` to create your own.

## How it works at runtime

Claude Code reads `CLAUDE.md` at the project root automatically. The `.claude/` subdirectory holds the rest of the layers, which you reference explicitly when invoking an agent.

A typical invocation:

```
Forge: read FORGE.md and PROJECT_WEBAPP.md, then add an idempotency key to the
webhook handler in src/api/stripe.ts.
```

What happens in Claude's context window, in order:

1. `CLAUDE.md` is already loaded (Claude Code does this automatically)
2. `FORGE.md` is loaded (you asked for it by name)
3. `PROJECT_WEBAPP.md` is loaded (you asked for it by name)
4. The task itself is in your message

The agent now has:

- Universal discipline (read before write, no scope creep, hold position under challenge)
- Builder role discipline (you implement, you do not architect; tests before code)
- Project-specific rules (idempotency keys are mandatory on webhook handlers in this project)
- A concrete task

The agent has enough context to do the work correctly and enough boundaries to refuse if the task implies overstepping.

## The four roles

`adl` ships with four roles. The pattern is deliberate: they cover the full lifecycle of any technical change — *what exists* (Scout), *what to do* (Quill), *the doing* (Forge), and *did it actually meet the contract* (Warden).

| Role | What they do | What they refuse |
|---|---|---|
| **Forge** | Implements code against a spec | Decides what to build, expands scope, makes architecture decisions |
| **Quill** | Writes specs, docs, READMEs, comments | Writes code (except illustrative snippets) |
| **Scout** | Investigates existing systems, traces flows, reproduces bugs | Decides what to change, writes the fix |
| **Warden** | Verifies that delivered work meets its `/goal` manifest, writes the proof artifact, signs off or kicks back | Patches failures, edits the manifest, negotiates partial sign-off |

This separation is the source of most of the value. When an agent has a narrow role with explicit "what you do not own" boundaries, it stops doing the things you did not ask for. When you want it to do something outside its role, you invoke a different role.

The "what you do not own" sections in each overlay are deliberately heavier than the "what you own" sections. That asymmetry is intentional: bounding behavior is harder than enabling it, and most LLM coding failures are scope-creep failures.

## The `/goal` contract (v1.1.0+)

Every code-changing slice gets a manifest at `.claude/goals/<task-id>.yaml` that declares its `done_when` checks (tests, commands, file constraints, diff constraints). Workers cannot self-assess "done" — Warden runs the manifest, writes `.claude/goals/<task-id>.proof.json`, and a Stop hook refuses to release the worker until `signed_off: true`. For Scout investigations and design slices where the verifier is operator judgment, Warden emits `signed_off: "pending"` plus a reviewer checklist; the operator flips it manually.

Full spec lives at `.claude/docs/GOAL_PROTOCOL.md`. Reference Stop-hook config at `.claude/settings.example.json`.

## Verify against reality — and why it matters now

`adl` is the **discipline layer of [The Machine](https://frontierinfra.org)**: Part 0 (a contract before work starts) and Part 4 (verify against reality, `verifier ≠ subject`), made native to Claude Code. The distinction is load-bearing. Claude Code's built-in `/goal` evaluator judges a condition against *the conversation transcript* — what the agent **said** it did. Warden judges against *ground truth* — it runs the `done_when` checks and signs a proof from their actual results. A worker can talk its way past the transcript; it cannot talk its way past a failing test.

This is also what lets the discipline outlive any one model. When a model is replaced — or, as in June 2026, [recalled by a government letter overnight](https://jasonbrashear.substack.com/p/the-first-recall) — the contract, the checks, and the proof are all on disk, owned by you. The work survives because the verifier was never the model.

**Shipped today:** the four-layer model; the `/goal` manifest → Warden → signed `proof.json` → Stop-hook gate.
**Roadmap (not yet shipped, marked honestly):** an owned, local model to sign the `human_review` residue Warden currently hands back to you; a ratified amendment channel so a contract can be corrected when execution falsifies it, without a loop; a multi-model council for the design-judgment calls a single verifier shouldn't make alone.

The discipline has been turned on its own enforcement machinery — and survived it. See [`CASE_STUDY.md`](CASE_STUDY.md): a real audit that hardened the goal-contract gate by catching it blocking finished work, fixed three bugs under a contract, and shipped the fix across seven profiles.

## The orchestrator (optional but useful)

`ARGENT.md` is the orchestrator overlay. You can use it as the configuration for a top-level agent that routes requests to specialists, or you can read it as a guide for how *you* should manually route work to the right role.

For solo developers, the orchestrator is mostly a thinking aid. You read `ROUTING_PATTERNS.md`, internalize when to use Scout versus Forge versus Quill, and the orchestrator config becomes the reference doc you point new agents at.

For more complex setups (multi-agent systems, custom Claude integrations), `ARGENT.md` is the literal config you load into your orchestration layer.

## Project overlays

Project overlays encode the things that are true for one project specifically:

- Non-negotiable rules (security boundaries, data-handling requirements)
- Vocabulary (the exact terms your project uses)
- Engineering constraints (test requirements, library choices, architectural invariants)
- Active scope (what is being worked on, what is frozen)
- Role-specific notes (what each role needs to know in this project)

The included examples (`PROJECT_WEBAPP.md`, `PROJECT_API.md`, `PROJECT_CLI.md`) demonstrate the pattern across three common project shapes. They are not your project. They are reference material showing how to structure your own overlays. Copy `PROJECT_TEMPLATE.md`, fill it in for your project, and delete the examples.

## What this does not do

To be honest about scope:

- **It does not enforce the rules.** Claude Code follows the instructions, but a sufficiently determined model can still violate them. The layers raise the floor; they do not guarantee compliance.
- **It does not eliminate the need for review.** Karpathy's "watch them like a hawk" advice still applies. This system makes the hawk's job easier, not unnecessary.
- **It does not replace project-specific knowledge.** A great project overlay still requires you to know what matters in your project. The framework is the scaffolding; you supply the content.
- **It does not auto-detect project context.** When you have multiple project overlays, you point Claude at the right one explicitly. Future versions may include path-based auto-loading.

## The failure modes this addresses

Each layer attacks a subset of common LLM coding failures:

| Failure mode | Where it is addressed |
|---|---|
| Wrong assumptions run with silently | `CLAUDE.md` section 2 (surface confusion) |
| Sycophantic capitulation | `CLAUDE.md` section 3 (hold position) |
| Bloated abstractions | `CLAUDE.md` section 4 (simplicity default) |
| Scope creep into adjacent code | `CLAUDE.md` section 5 (surgical edits) |
| Comments and code edited as side effects | `CLAUDE.md` section 7 |
| Reporting intent instead of result | `CLAUDE.md` section 8 |
| Builder making architecture decisions | `FORGE.md` (what you do not own) |
| Writer drifting into implementation | `QUILL.md` (what you do not own) |
| Investigator confabulating findings | `SCOUT.md` (citation discipline) |
| Worker self-assessing "done" without verification | `WARDEN.md` + `/goal` manifest + Stop hook |
| Orchestrator dispatching "general-purpose" workers | `ARGENT.md` dispatch contract (role + project + manifest required) |
| Project-specific rule violations | Project overlay non-negotiable rules |
| Wrong project context applied | Orchestrator project identification |

Read `.claude/docs/LAYERING_MODEL.md` after install for a deeper walkthrough.

## Installation

The installer is interactive. It checks before overwriting anything.

```bash
./install.sh                    # installs into current directory
./install.sh /path/to/project   # installs into specified directory
./install.sh --minimal          # base + roles + template only, skip example projects
./install.sh --yes              # non-interactive, accept all defaults
```

After install, run the smoke test in your Claude Code session:

```
Read CLAUDE.md, then summarize in three sentences what behaviors it requires.
```

A correct response will mention reading before writing, surfacing confusion before acting, and surgical edits. If the agent skips these, the file did not load correctly.

## Versioning your overlays

Each layer file has a `Version:` line at the top. Bump it when behavior changes. This matters most for project overlays, which evolve as your product evolves. Role overlays and base `CLAUDE.md` should rarely change. Check the overlays into your repo and review changes in PRs just like code.

## Customization

The defaults are opinionated but the structure is the point. Common customizations:

- **Replace the three roles** if your work needs different specialists. The pattern (identity, what-you-own, what-you-do-not-own, discipline, failure modes, handoff protocol) is what to preserve. The specific roles are illustrative.
- **Add roles** by copying an existing role overlay and editing. Common additions: a security reviewer, a performance specialist, a UX writer.
- **Tighten or loosen `CLAUDE.md`** if section 4's simplicity defaults conflict with your team's house style. Just remember that loosening propagates to every agent in every project.

## Background and design rationale

The four-layer model emerged from operating multi-agent systems in production. Single-file `CLAUDE.md` configurations work for one project but break when you cross project boundaries, and they conflate three distinct concerns: how an agent should think in general, what role it plays, and what the current project values.

Separating these into layers means:

1. You can fix universal failure modes once, in `CLAUDE.md`, and every agent in every project benefits.
2. You can specialize without rewriting the base. Adding a new role is one file.
3. You can switch projects without context contamination. The agent reads a different overlay; the rest of the stack is the same.
4. You can audit behavior by reading the layers. The reasons for any agent decision should trace back to specific layer sections.

The role separation (build / write / investigate) maps to the actual lifecycle of any change: you understand the system (Scout), you decide what to do (Quill), you do it (Forge). Conflating these is the source of most agent failures.

The "what you do not own" sections are the most important part of each role overlay. They are the explicit license to refuse work that does not fit. Without them, agents drift toward becoming generalists who are mediocre at everything.

## Contributing

This is an opinionated starting point. PRs welcome for:

- Additional example project overlays for common project shapes
- Additional roles that have proven useful in practice
- Documentation improvements
- Installer bugs

Not accepted:

- Changes that relax the precedence rules
- Changes that conflate role and project concerns
- Decoration without operational impact

## License

MIT. Use it, modify it, ship it. Attribution is appreciated but not required.

## Acknowledgments

The base `CLAUDE.md` discipline draws directly on the failure modes Andrej Karpathy documented in his late-2025 Claude Code notes ([X thread](https://x.com/karpathy/status/2015883857489522876) · [Hacker News](https://news.ycombinator.com/item?id=46771564)). The layered architecture is influenced by years of building multi-agent systems where flat configurations consistently failed at scale.
