# Scenario catalog — the shared artifact (v1)

Without it, PM, QA and dev talk about "the test" without talking about the same thing: the catalog is
where a scenario is born (refinement, bug or exploration) and where you see what already became
automation. It is the source `test-strategy`, `qa-spec` and `bug` read and write.

**Where it lives:** `scenarios/<journey>.yaml` at the repository root (one file per journey:
`checkout.yaml`, `signup.yaml`). Versioned with the code — a scenario is code, not a spreadsheet.

## Format

```yaml
# scenarios/<journey>.yaml
- id: checkout-014          # required, stable, NEVER recycled
  issue: 123                # the GitHub issue (the epic, or the bug)
  journey: checkout
  criticality: high         # high | medium | low
  given:                    # traits per aggregate (test-data)
    customer: [past_due, subscribed]
  when: "the customer tries to start a second subscription"
  then: "the system blocks it and shows the outstanding balance"
  target_level: L1          # L0 | L1 | L2 | L3 | L4 (test-strategy/references/test-levels.md)
  status: draft             # draft | automated | manual-permanent
  spec: null                # path of the test file once automated
  origin: refinement        # refinement | bug | exploratory
```

**Nothing more than this in v1.** A field nobody fills in should be born outside: the acceptance test
is a QA creating a valid entry **alone, in under 5 minutes**. If that fails, the schema is too big —
cut a field, do not train people.

## The rules worth defending

- **`id` is stable and never recycled.** It ties scenario ↔ spec ↔ bug ↔ issue; recycling an id
  erases history. Prefix = journey (`checkout-`, `signup-`), then a sequential number. Lowercase on
  purpose: it never gets confused with an issue number or another tracker's key.
- **`given:` speaks in domain traits**, not records ("a past-due customer", not "customer id 4821").
  A trait that does not exist is **a request to `test-data`**, not an excuse to use staging data.
- **`status: automated` requires `spec:` filled in** and the file existing — `preflight` warns when
  the two diverge (`preflight/scripts/qa-lint.sh`).
- **`manual-permanent` is a decision, not a pending item.** It is for what only a human judges
  (visual perception, content, a flow with a third party out of your control). Record it and stop
  treating it as debt.
- **A bug's scenario enters with `origin: bug`** and the bug's issue number in `issue:` — that is how
  the regression suite grows by itself, and in the right place (`bug`).

## How to start (a repo with no catalog)

Migrate **3 real scenarios by hand** — the three the team retests most — and stop. A big catalog at
the start is born stale; a three-entry catalog the team uses the following week becomes a habit.
After that, every new scenario enters through `test-strategy` (refinement), `bug` (a defect) or
`exploratory` (`references/exploratory.md`).
