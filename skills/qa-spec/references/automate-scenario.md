# Playbook — Automate a scenario from the catalog

**Location:** `skills/qa-spec/references/automate-scenario.md` · referenced by `qa-spec`
**When:** a scenario leaves `draft` and becomes an automated test — QA's main loop
**Goal:** that the scenario becomes a test that **fails when the rule breaks**, and nothing more

> **Failure contract (applies to every step):** if a step cannot be completed, **stop, say exactly what is missing and do not improvise**. Never work around a gate. A scenario returned with the reason is worth more than a spec delivered with invented data.

---

## Gate 0 — Preconditions

Do not start without all three. If any is missing, stop here and report.

- [ ] **The scenario exists in the catalog** (`scenarios/<journey>.yaml`) with `when` and `then` filled in. A scenario without both is not a scenario, it is a reminder — send it back to whoever recorded it.
- [ ] **`target_level` defined** (L0–L3). Without a level, there is no decision to confirm in step 2.
- [ ] **The factories for the traits in `given:` exist** (`test-data`). Check trait by trait, by name.

**Hard gate:** a missing trait → **refuse to generate**. Say which one is missing, on which aggregate, and offer to create the factory. Do not use staging data, a fixed id, a user "that already exists" or `SELECT ... LIMIT 1` — that is how the suite goes back to depending on the environment, and the effect only shows up weeks later, in someone else's test.

**Output of this step:** the catalog entry pasted into the conversation + the list of traits, each marked existing or missing.

---

## Step 1 — Reread the scenario and name the rule under test

1. Read `when`/`then` **as written**. Do not reinterpret: if it is ambiguous, it is a question for the author, not an assumption of yours.
2. Write in one sentence **which rule** the `then` asserts ("a subscription is blocked when there is an outstanding balance").

**Output:** the rule's sentence. It is what the assertion in step 4 and the mutation in step 5 will chase.

---

## Step 2 — Confirm or challenge the level

Compare the rule from step 1 with the rungs in `test-strategy/references/test-levels.md`.

- If `target_level` is the lowest that still proves the rule, confirm it in one line.
- If it fits lower, **argue for going down** with the three parts: **gain** (speed, stability, the cause pointed at directly), **loss** (what stops being covered) and **what to do about the loss** (nothing, or a second, smaller scenario at the level above).

Example of an acceptable verdict: *"requested L3; the rule is domain logic and proves at L0 — ~40x faster and it points at the failing line; it loses the guarantee that the screen calls this use case; I propose L0 + one L3 just for the display."*

**Gate:** changed level → update `target_level` in the catalog **with the reason** before writing code. A level decided in the conversation and not recorded is lost by the next session.

**Output:** the written verdict (confirm or go down) and the catalog consistent with it.

---

## Step 3 — Build the setup through the fixture

1. Create the state **only** through a factory/API fixture, with the traits in `given:`.
2. Generate the run's `runId` and use it in every identifier created.

Isolation rules (not repeated here): `test-data/references/isolation.md`.

**Gate:** do not move on until the setup runs **alone**, without the rest of the test, printing the ids it created. A setup that only works together with the test hides which step the failure came from.

**Output:** the setup block executed, with the list of ids created and the `runId`.

---

## Step 4 — Write the "when" and the "then"

1. **When:** the exact action of the scenario, only one. Do not chain two actions "while I'm here".
2. **Then:** the assertion on the **effect** the `then` describes — a value, a message, a persisted state, a published event. Never `toBeTruthy`, never "status 200" as the only proof, never a whole-screen snapshot.
3. Waits are **on a condition**, never on time.

**Gate:** one scenario per spec. If the file proves two things, it will not tell you which one broke — split it.

**Output:** the spec file created, and the suite green on the repo's test command (`context/references/conventions.md`).

---

## Step 5 — Mutation proof

1. Break, on purpose, the rule from step 1 in the production code (invert the guard, change the return, remove the effect, move the boundary).
2. Run the test: it **has** to fail, and the failure message has to describe the broken rule.
3. Revert the mutation and confirm it is green again.

Full procedure, and what to do when the mutation survives: `qa-spec/references/mutation-proof.md`.

**Gate:** the mutation survived (the test passed with the code broken) → the problem is the **assertion**, not the code. Fix it and repeat. **Do not move on with a surviving mutation** — otherwise you deliver a test that will never fail anything.

**Output:** the red run's output + the sentence describing the mutation used ("inverted the outstanding-balance guard").

---

## Step 6 — Three runs in random order

Run the journey's suite **three times**, shuffling the order, with the repo runner's flag (confirm with `--help`: Vitest `--sequence.shuffle`, Jest `--randomize`, pytest with `pytest-randomly`; in Playwright, `--repeat-each=3` with parallel workers).

**Gate:** any red here is order coupling or shared data — **it is not "instability"** and it is not solved by rerunning. Go back to step 3.

**Output:** three green runs, pasted or summarized with the command used.

---

## Step 7 — Close

- [ ] Catalog updated: `status: automated` and `spec: <path>`
- [ ] PR opened with the scenario entry in the body and the mutation sentence from step 5
- [ ] A comment on the issue with the scenario id (`issues`)
- [ ] **A plain-language paragraph** with three parts: **what the test proves**, **what it does not prove**, **what will legitimately make it break** (a rule change, not a refactor)

The paragraph is not a formality: it is what lets the reviewing developer (`review`) judge in one minute whether the coverage is the one the team thinks it has.

---

## Anti-patterns

- **Generating the test without the trait's factory.** It becomes a staging dependency: it passes today, vanishes when the environment is recreated, and nobody ties the failure to its cause.
- **Accepting the requested level without examining it.** That is how every suite becomes E2E — slow, expensive and run only the day before release.
- **Going down a level without stating the loss.** Coverage disappears with nobody deciding it; the hole shows up in production.
- **An assertion that mirrors the implementation** (called method X). It breaks on every refactor and passes on every bug.
- **Skipping the mutation proof because "it obviously works".** A test that never fails is maintenance cost pretending to be a safety net.
- **Running it only once.** Order coupling only shows up when shuffling; found later, it becomes quarantine and distrust of the whole suite.
- **Closing without updating the catalog.** The scenario stays in `draft` forever, and the automation queue starts lying to everyone.
