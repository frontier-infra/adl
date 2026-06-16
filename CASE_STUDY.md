# Case study — the discipline auditing its own enforcement

> How a model audit turned into a stress test of the verification layer itself: the
> goal-contract gate caught an agent trying to close finished work, exposed three of its own
> bugs in the process, and was fixed — under contract — and shipped across seven Claude Code
> profiles. This is `adl` eating its own cooking.

Companion essays (the human story): [The First Recall](https://jasonbrashear.substack.com/p/the-first-recall)
and [The Prompt Is Not The Operating System](https://jasonbrashear.substack.com/p/the-prompt-is-not-the-operating-system).

---

## 1. The occasion: a model that lasted three days

On 2026-06-09 a frontier model (Fable 5) became available. On 2026-06-12 it was suspended by a
US government export-control directive — gone by letter, overnight. An operator had three days
with it and a frozen archive of its sessions. The obvious instinct: find what made it decide
better than its successor and port that back.

So we ran the audit. And the audit is where the discipline starts.

## 2. The audit, and its honest (negative) result

We distilled the frozen sessions into behavioral traces and computed deterministic metrics,
then — crucially — put every apparent finding through a **paired natural experiment**: the same
operator, the same files, the same session, the model switched mid-stream, so task and harness
are held constant by construction. `verifier ≠ subject`, applied to our own conclusions.

Seven candidate findings died under that control (harness artifacts, usage/duration artifacts,
task-mix). **One** survived — a tool-choice style difference — and even it was *not*
outcome-validated. A 5-model council then reviewed our write-up and caught us grading the
survivor more gently than its siblings; we re-ran the test it demanded; the survivor held; the
council's own confident-but-untested prediction did not. The discipline bound the reviewers too.

The load-bearing result was negative and it was the point: **the thing worth keeping about a
model — its judgment under ambiguity — is not in the tool-call logs.** You cannot rebuild the
object from its shadow. Which means the durable asset was never the model. It was the harness
around it. That is The Machine's thesis, and the audit had just proven it on its own subject.

## 3. The pivot: turn the discipline on the discipline

If the harness is the asset, the harness has to be sound. So we pointed the same method —
verify against reality, never self-grade — at the **goal-contract gate**: the operator-installed
Stop-hook enforcement (`witness` + `disposition-gate`) that refuses to let a session declare
done while it has surfaced conditions it hasn't accounted for. (This is the *operator-level*
count gate — the user-scoped instance of the same `verifier ≠ subject` principle this repo ships
as **Warden**. The audit recommended reconciling the two; that is roadmap.)

We didn't have to construct a test. The gate ran a live one on us.

## 4. The dogfood moment: the gate blocks its own repair

While the session worked, the gate fired and refused to let it stop:

```
DISPOSITION GATE: the session surfaced 2 pre-existing condition(s) that the final message
does not account for ...
  failing_test (1):
    - distilled OK: 98 / 98   failed: 0          ← a SUCCESS line, flagged as a failure
```

That is the gate doing its core job correctly — *catching an agent trying to close in silence* —
and, in the same breath, exposing **three of its own bugs**:

1. **False positive.** `98 / 98   failed: 0` is a success report; the matcher caught the word
   "failed" and missed that the count was `0`.
2. **Reflexive self-capture.** Reading the witness log *to comply* printed its contents back,
   which the witness re-captured as a *new* condition. Inspecting the verifier fed the verifier.
3. **One-behind read race.** The Stop hook read the transcript a beat before the newest message
   committed, so it kept grading the *previous* reply — a compliant disposition log scored as if
   it weren't there.

The honest lesson arrived immediately, and it's the whole reason this matters: **a verifier you
cannot repair while it judges you is a verifier you will learn to disarm** — and a guardrail you
reflexively disarm has already failed. The fix is precision and timing, never loosening what it
blocks.

## 5. The fix, governed by the thing it was fixing

The repair did not get to free-ride. It went through `/goal` like any other slice. The contract
that governed it (shown verbatim — *this* is what "verifiable" looks like):

```
=== LOCKED CONTRACT (distilled) ===
GOAL: Harden the goal-contract gate so it stops looping on completed work — fix the failed:0
false positive, the reflexive self-capture, and the one-behind read race, with a RED→GREEN test
harness, preserving fail-open. No change to the gate's core contract or strictness.
ACCEPTANCE:
  - witness: failed:0 / passing-shaped lines no longer recorded as failing_test (test proves).
  - witness: tool calls touching the goal-contract machinery are not witnessed (test proves).
  - gate: grades the NEWEST message (stdin-or-retry); identical re-block escalates loud, never
    loops (test proves).
  - witness entries deduped; fail-open-on-error preserved (test proves).
  - All tests green against fixtures incl. the real witness log from this very session.
NON-GOALS: changing the header+tags≥conditions contract; loosening real-condition detection;
  blanket fail-open-after-N for unmet work.
BUDGET: witness + disposition-gate + one test file. Operator wires to live config after review.
TRIPWIRE: if the race can't be resolved hook-side, STOP — it's a harness flush issue, report up.
=== Work only to this contract. ===
```

Every `ACCEPTANCE` line is a check, not a vibe. The work produced three artifacts — the two
fixed hooks plus a `test_gate.py` with **24 checks, RED→GREEN**, including the *actual* witness
log from the session as a regression fixture. Under the fix, that real log's three rows collapse
correctly: the two false positives drop, the one genuine error is kept.

The fixes, precisely:
- **Fix 1** — the count-before-"failed" patterns now require a non-zero count and reject the
  `failed:`/`failed=` colon form; the zero-failure shapes are ignored.
- **Fix 2** — Bash commands that inspect the goal-contract machinery aren't witnessed, and the
  witness's own `- kind ::` / jsonl echo shape is guarded. The verifier is now inert to its own
  inspection.
- **Fix 3** — the gate grades the newest message via stdin-or-retry, with a loud repeat-block
  backstop that surfaces the disarm hint instead of silently re-nagging. It never auto-passes
  unmet work, and `fail-open-on-error` is preserved.

## 6. Ship: one shared directory, seven profiles

A read-only check (before touching anything) found that all seven Claude Code profiles point
their Stop-hook config at **one shared hooks directory** — so the fix deployed once and covered
every profile. Backup taken, files wired, verified byte-identical to the tested versions, syntax
checked, fail-open smoke-tested (garbage → `approve`, no-contract → `approve`). The very session
that had been looping then closed cleanly on the now-fixed gate.

## 7. What this demonstrates about `adl`

- **It catches the failure it exists to catch.** The gate blocked done-in-silence even on the
  session repairing it. That is the job, working.
- **The discipline survives contact with itself.** The fix passed through the same `/goal`
  contract, the same `verifier ≠ subject`, the same RED→GREEN proof — no exceptions for the
  maintainer.
- **Honesty over polish.** A guardrail's worst failure is crying wolf, because the operator
  learns to ignore it. We fixed precision, not strictness; the contract's `NON-GOALS` forbade
  loosening what the gate blocks.
- **It is a harness, and harnesses outlive models.** The whole project began because a model was
  recalled in a week. The work it had produced kept running, because the system was never the
  model. This case study is that thesis, applied one level down — to the verifier itself.

> A bug found by your own discipline, fixed under your own contract, shipped with a regression
> guard, is not an embarrassment. It is the proof the discipline is real.
