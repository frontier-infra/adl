# Routing Patterns

How to decide which agent to invoke and in what order.

For solo developers, this doc is the reference you use to manually route work to the right role. For multi-agent setups, this doc describes the routing logic the orchestrator agent should follow.

## Classification first

Before routing, classify the request:

| Signal | Likely classification |
|---|---|
| "Build," "implement," "add," "fix" + spec or test | Forge |
| "Document," "write up," "draft a spec," "explain" | Quill |
| "Investigate," "trace," "find out," "how does X work" | Scout |
| "Compare," "audit," "verify" | Scout, possibly with Quill writeup |
| "Refactor," "improve," "make better" | Decompose: Scout then Quill then Forge |
| "What should we do about X" | Escalate to the human |

If classification is ambiguous, ask before delegating.

## The decomposition rule

Any task containing both "what" and "how" needs decomposition. Specialists do one of:

- Forge: implement a known *what*
- Quill: define the *what*
- Scout: discover the *what* that already exists

Fuzzy tasks that combine these always decompose to Scout then Quill then Forge.

## Common patterns

### Direct invocation

A well-specified task goes to one agent.

```
"Forge: add a null check on line 42 of foo.ts"
→ Forge (direct)
```

### Investigate-then-act

A task with unknowns starts with Scout.

```
"Why is the webhook handler dropping requests under load?"
→ Scout investigates and reports findings
→ Operator reviews findings before deciding on a fix
```

### Spec-then-build

A task with a known goal but no spec starts with Quill.

```
"We need an audit log for tenant access."
→ Quill writes the spec
→ Operator approves the spec
→ Forge builds against the spec
```

### Investigate-spec-build

The full chain for fuzzy improvement tasks.

```
"The demand letter generator is too slow."
→ Scout investigates current behavior, identifies bottlenecks
→ Quill writes a spec for the fix
→ Forge implements
```

### Parallel reconnaissance

For comparison or audit work.

```
"Compare how System A and System B handle multi-tenant isolation."
→ Scout(A) and Scout(B) in parallel
→ Quill writes the comparison
```

### Pipeline with operator gates

For high-stakes work, the human approves between stages.

```
"Refactor the Stripe webhook handler."
→ Scout reports current behavior [operator gate]
→ Quill writes refactor spec [operator gate]
→ Forge implements [operator gate]
```

## Anti-patterns

### Single-agent for fuzzy work

```
"Forge: make the demand letter generator better."
```

Forge does not know what "better" means. This generates speculative code that is hard to review and almost always misses the actual need. Decompose first.

### Skipping Scout when assumptions are unverified

```
"Forge: optimize the database query in src/services/cases.ts:142."
```

If nobody has verified that line 142 is the bottleneck, Forge will optimize the wrong thing. Send Scout first if the diagnosis is unverified.

### Asking Quill to write code

```
"Quill: write the implementation for the new endpoint."
```

Quill writes about code, not code. Route to Forge with a spec from Quill.

### Skipping the handoff context

```
Scout returns findings.
Operator immediately invokes Forge.
```

Quill should write the spec from Scout's findings before Forge implements. Without the intermediate spec, Forge has to make decisions Quill should be making, which violates Forge's "what you do not own" boundary.

## Failed delegation recovery

If a specialist returns "I cannot do this":

- **Forge cannot proceed without a spec** → route to Quill for the spec, then back to Forge
- **Quill cannot write a spec without findings** → route to Scout for investigation, then back to Quill
- **Scout cannot find what was asked** → report to operator; do not improvise

Never retry the same delegation with the same context and expect a different result.

## When to refuse a task

This is the operator's call, but here is the reasoning:

- A task that violates a project's non-negotiable rule → refuse and surface
- A task that requires a destructive or irreversible action → require explicit confirmation
- A task whose execution would corrupt operator data or expose customer data → refuse and surface

In these cases, escalate with the specific concern and ask for confirmation or an alternative approach.

## Latency tradeoffs

Decomposition adds turns. For trivial tasks, that is overhead. For non-trivial tasks, it is the difference between getting the right thing built and getting something that has to be rebuilt.

Rough guidance:

| Task | Pattern | Turns |
|---|---|---|
| Single-file edit, clear spec | Direct | 1 |
| Single-file edit, unclear spec | Quill then Forge | 2 |
| Multi-file change, known design | Direct to Forge | 1 |
| Multi-file change, unclear design | Scout, Quill, Forge | 3 |
| Bug fix with unknown cause | Scout then Forge | 2 |
| New feature on existing system | Scout, Quill, Forge | 3 |

When in doubt, decompose. The cost of an extra turn is less than the cost of building the wrong thing.

## For solo developers

You are the orchestrator. The patterns above describe how to think about your own delegation. Three practical habits:

1. Before invoking Forge, ask yourself: "Is the spec clear enough that Forge cannot misinterpret it?" If not, draft the spec (or have Quill draft it) first.

2. Before invoking Forge on a bug, ask yourself: "Have I or Scout verified where the bug actually is?" If not, send Scout first.

3. When Forge returns work, read the handoff report before reading the diff. The report tells you what to look for; the diff is detail.
