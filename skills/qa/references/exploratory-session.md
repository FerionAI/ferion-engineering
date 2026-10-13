# Playbook — Exploratory session with a browser agent

**Location:** `skills/qa/references/exploratory-session.md` · referenced by `qa` (the L4 skill)
**When:** QA is about to explore a journey with a browser agent (or by hand, with the agent recording)
**Goal:** that the session ends in a **versioned artifact**, not in lost knowledge

> **Failure contract (applies to every step):** if a step cannot be completed, **stop, say exactly what is missing and do not improvise**. Never work around a gate. An interrupted session with a record is worth more than a "finished" session with invention.

---

## Gate 0 — Preconditions

Do not start without all three. If any is missing, stop here and report.

- [ ] **`runId` generated** in the format `qa-<person>-<YYYYMMDD>-<n>`. Everything created in this session carries that prefix — it is what allows cleaning up afterwards and what separates your trail from someone else's.
- [ ] **Scope defined:** ONE named journey. "Explore the system" is not a scope and produces a session with no conclusion.
- [ ] **Time-box defined** (suggested: 45 min). Without a time-box the session does not end, it is abandoned — and an abandoned session leaves no record.

**Output of this step:** one line at the start of the record with `runId`, journey and time-box.

---

## Step 1 — Gather what is already known

Before exploring, know what does not need exploring.

1. Read `scenarios/<journey>.yaml` and list what is already `automated` (`scenario-catalog.md`).
2. Read the open bugs for the journey: `gh issue list --label type:bug --search "<journey>"`.

**Output:** a short list of "already covered" and "already known".
**Why:** exploring what CI already covers is the most common waste and the most invisible one — nobody notices it happened.

---

## Step 2 — Build the state through the factory, never by clicking

1. Identify the data states you need (e.g. `customer[past_due, subscribed]`, `plan[at_capacity]`).
2. Create them through the API fixture or the back office (`test-data`), **always with the `runId` in the identifier**.

**Gate:** if a state you need does not exist as a trait and cannot be produced through the back office, **stop**. Record the missing trait as a pending item and keep exploring **only** what is possible without it. Do not build the state by alternative routes (direct SQL, editing an existing record) — that contaminates the shared environment and the effect shows up days later, in someone else's test.

**Output:** the list of entities created, with id and `runId`.
**Never:** navigate the UI to prepare state. The browser only enters in step 3.

---

## Step 3 — Explore with heuristics, not by sweeping

Clicking on everything is not exploration, it is expensive noise. Use, in this order:

1. **The main path of the journey**, once, to establish the baseline.
2. **Edges by field type** — apply the edge catalog: date (month/year rollover, time zone, daylight saving), money (rounding, cents, zero, negative), text (unicode, emoji, accents, empty, length limit), national id (invalid, duplicated, formatted), collection (empty, one item, pagination limit).
3. **Interrupt and come back** — leave midway, come back, reload the page, use the browser's back button, open it in two tabs. Most state defects live here.
4. **Combinations of traits** nobody tests together (`past_due` + `plan at capacity` + `payment declined`).
5. **Permission** — the same journey with a profile that should not be allowed.

**Note-taking rule:** every anomaly is written down **on the spot**, with `runId`, exact steps and evidence (a screenshot). Notes from memory at the end of the session lose the half that matters — the exact steps.

---

## Step 4 — Record (this is where the session becomes an asset)

Each finding becomes **one** of three things, never none:

| Finding | Destination |
|---|---|
| Defect | A bug issue (`references/bug-report.md`) **+** a scenario in the catalog with `origin: bug`, `status: draft` |
| Correct behavior not yet covered | A scenario in the catalog, `origin: exploratory`, `status: draft` |
| A business-rule question | A question to the PM, recorded on the epic's issue — it does **not** become a scenario until answered |

Minimum catalog entry (without it, it does not count as recorded):

```yaml
- id: checkout-021
  journey: checkout
  criticality: medium
  given: { customer: [past_due], plan: [at_capacity] }
  when: "the customer reloads the page in the middle of checkout"
  then: "the subscription is not duplicated"
  target_level: L1
  status: draft
  origin: exploratory
```

**Gate:** a scenario without `when`/`then` filled in is not a scenario — it is a reminder. Complete it or drop it.

---

## Step 5 — Close

- [ ] Every finding became a bug, a scenario or a question (step 4)
- [ ] Data created was discarded, or left to the cleanup job by `runId` prefix — **never** left without a prefix
- [ ] L0–L2 scenarios marked as the **automation queue** (they are the cheap ones; automate them before the expensive ones)
- [ ] A 3-line summary: what was explored, what was found, what was left outside the time-box

**Criterion for a successful session:** it is not "I found a bug". It is **"what I learned is recorded so someone else can use it"**. A session with no finding and a clear record of what was covered is a useful session — it shrinks the search space of the next one.

---

## Anti-patterns

- **Exploring without a scope.** Produces a long session, no conclusion and no record.
- **Preparing state by clicking through the UI.** Slow, fragile, and it pollutes everyone's environment.
- **Taking notes at the end, from memory.** Loses the exact steps, which is the part the developer needs.
- **A finding that becomes only a chat message.** It evaporates. If it is not on an issue or in the catalog, it did not happen.
- **Creating data without a `runId`.** It becomes permanent garbage in the shared environment, and nobody knows whose it is.
- **Opening a bug without a scenario.** The bug is fixed, and the regression comes back in three months with nobody noticing.
- **Letting the agent choose what to explore.** It sweeps; heuristics are a human decision. The agent executes and records.
