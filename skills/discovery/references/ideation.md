# Ideate — diverge and converge with method

The failure mode is universal: the first idea gets evaluated alone, survives by default, and becomes
the plan. Divergence is the cheap insurance against that.

## 1. Define (frame the problem before solving it)

**Point of view:** `<persona>` needs `<need>` because `<insight from the evidence>`.

**How Might We:** turn the pain into an open question — "How might we let someone resume a purchase
without re-entering everything?"

A good HMW is not too narrow (it contains the solution: "how might we add a save button") and not too
broad ("how might we improve checkout"). If everyone in the room writes the same solution, it was too
narrow.

## 2. Diverge (2–3 genuinely different approaches)

Different **angles**, not three flavors of one idea:

| Angle | Question it answers |
|---|---|
| **Smallest thing that works** | what if we had one day? |
| **Lowest risk** | what if being wrong were expensive? |
| **Best experience** | what if effort were not a constraint? |
| **Remove instead of add** | what if we deleted the step causing the problem? |

The fourth is the one people skip and it is often the winner. The best solution to a confusing form
field is frequently not a better field.

Write each one as a paragraph, not a spec. Do not evaluate while diverging — that collapses the set
back to one.

## 3. Converge (criteria, not enthusiasm)

| Approach | Impact | Effort | Risk | Reversible? |
|---|---|---|---|---|
| A | high | low | med | yes |
| B | high | high | low | no |

Then apply the write-less-code instinct: **the smallest one that actually solves the problem**. Not
the most complete, not the most impressive.

**Reversibility deserves its own column.** A reversible decision can be made fast and cheaply; an
irreversible one deserves the extra week. Treating them the same is how teams are simultaneously too
slow and too reckless.

## 4. Recommend

One recommendation, one paragraph of reasoning, the discarded options named in a line each so nobody
re-proposes them next month. This becomes the what/why of `spec-flow`'s `specify`.

Do not deliver a menu. A survey of options with no recommendation moves the decision to someone with
less context than you.

## Validating before building

For a big or uncertain bet, the cheapest validation is not code:

- A **prototype** (even a static mockup) put in front of five users
  (`usability-testing.md`).
- A **spike** with a time-box, when the uncertainty is technical rather than human.
- **The existing data** — sometimes the analytics already answers the question and nobody looked
  (`empathy-and-signals.md`).

Then: `design-review` validates the design against the constitution, and `spec-flow` turns the chosen
approach into a spec.
