# Playbook — Review a test written with AI

**Location:** `skills/review/references/review-ai-test.md` · referenced by `review`
**When:** a spec authored by QA with AI reaches the developer for review (and QA follows along in step 5)
**Goal:** decide where this test goes — blocking gate, nightly or rewrite — and teach along the way

> **Failure contract (applies to every step):** if a step cannot be completed, **stop, say exactly what is missing and do not improvise**. Never work around a gate. A review returned with the reason is worth more than an approval out of fatigue.

---

## Gate 0 — The automated part already passed

Human review **starts where the automated one ends**. Confirm on the PR before reading a line:

- [ ] **The preexisting-data and fixed-wait lint** is green (`preflight/scripts/qa-lint.sh`)
- [ ] **A mutation proof is declared** in the PR body, with the mutation used in one sentence
- [ ] **The catalog scenario** is cited, with id and level

**Gate:** if any is missing, **send it back without reviewing** and say which one. Spending human attention on what the machine catches is the most common way of letting through what only a human catches.

**Output of this step:** the three items confirmed, or the return with the missing item named.

---

## Step 1 — **Can** the assertion fail?

The most serious question, and the first. Read the assertion and answer: **is there an input that brings it down?**

1. Find the `expect`/`assert` that corresponds to the scenario's `then`.
2. Check the mutation declared on the PR: it attacks **the scenario's rule**, not just any line.
3. Distrust: `toBeTruthy`, `not.toBeNull`, an HTTP status as the only proof, a whole snapshot, an assertion only about the setup.

**Gate:** if the answer is "I cannot imagine what would make this fail", the verdict is already **rewrite** — stop here and say why. A test that cannot fail gives coverage in the report and zero protection.

**Output:** one sentence — "fails if X stops blocking" — or the rewrite verdict.

---

## Step 2 — Is the level right?

Compare what the test does with the rungs in `test-strategy/references/test-levels.md`.

- **L3 doing L0's job:** starts the whole system to prove a domain rule. Ask to go down, with the gain (time, stability, the cause pointed at) and the loss (what stops being covered).
- **L0 that mocks exactly the risk:** the mock replaced the rule under test; the test proves the mock. Ask to go up.

**Output:** keep / go down / go up, with one sentence of reason.

---

## Step 3 — Does the assertion prove the rule or mirror the implementation?

Signs of a mirror: it checks that a method was called, checks the internal order of execution, replicates the code's calculation inside the assertion itself, matches the object's structure instead of the value that matters.

**Rule:** the assertion has to stay valid if someone rewrites the implementation keeping the behavior. If a pure refactor would break the test, it is a mirror.

**Output:** a verdict per assertion, with the line cited.

---

## Step 4 — Will it break for the wrong reason?

Sweep the usual suspects and propose the swap:

| Fragility | Swap for |
|---|---|
| Selector by DOM path or style class | role/`data-testid` |
| Literal interface text | an i18n key, or an assertion on the effect |
| List order that is not guaranteed | comparison as a set, or explicit sorting |
| Date/time/time zone from the real clock | a clock fixed in the test |
| Randomness without a seed | a fixed seed, or an assertion on the property |

**Output:** a list of fragile points with the proposed swap — or "none", said explicitly.

---

## Step 5 — Three-way verdict

Pick **one** and write **one sentence of reason**. Never approve or reject in binary: a binary approval is what makes the reviewer approve out of fatigue at the end of the day.

| Verdict | When | What happens |
|---|---|---|
| **Goes into the blocking gate** | proves the rule, is fast and stable | runs on every PR |
| **Stays in nightly** | proves something real, but is slow or depends on the environment | runs outside the merge path, with an owner |
| **Needs a rewrite** | cannot fail, mirrors the implementation, or is at the wrong level | goes back to the author with the step that failed |

**Output:** the verdict, the sentence, and the record on the PR.

---

## Step 6 — Close (the review is teaching)

The author may not yet be able to evaluate their own result — the comment exists to teach, not only to block.

- [ ] Every comment says **why**, not only what ("this assertion passes even with the rule inverted — see the mutation")
- [ ] Whenever possible, point at **a good example in this repo** instead of describing the ideal
- [ ] A rewrite proposed as a **suggested diff**, not applied over it — whoever rewrites over the author delivers the test and keeps the learning
- [ ] Verdict and reason recorded on the PR; if there is an issue, on it too (`issues`)
- [ ] What became a new pattern goes into `context/references/conventions.md` — so the next test is born right

---

## Anti-patterns

- **Reviewing what the lint already catches.** It consumes the attention that should go to "can this assertion fail?".
- **Binary approval.** Without the nightly rung, every slow test becomes either a merge blocker or approved garbage.
- **"Improve this here" without saying what.** The author guesses, gets it wrong, and the cycle costs two more days.
- **Approving because CI passed.** Passing is the minimum; the question is whether it **would fail** when it should.
- **Rewriting the spec over the author.** Solves the PR and freezes the author at the same level — the same mistake comes back in the next PR.
- **Blocking on style.** Style is the lint's job; a human block is for what the machine does not see.
