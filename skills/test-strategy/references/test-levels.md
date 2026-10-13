# Test levels L0–L4 — and why going down is almost always right

One vocabulary for PM, QA and dev to decide **where** a scenario is tested. Without it, "let's test
this" always becomes E2E — and the suite gets slow, flaky and expensive exactly where it should be
cheap.

| Level | What it is | Cost/speed | The question that decides |
|---|---|---|---|
| **L0 · unit** | an isolated unit, no I/O: domain rule, calculation, pure component | ms | "is it a decision/calculation you can prove without leaving memory?" |
| **L1 · integration** | the unit with its real nearby dependencies (database, repository, service in a container) | seconds | "is the risk in how this talks to the infrastructure?" |
| **L2 · contract** | the agreement between two sides (OpenAPI, Pact, Avro schema), without starting the whole system | seconds | "is the risk the other repo changing under me?" |
| **L3 · E2E** | the system end to end along the user's path (full API or browser) | tens of seconds | "does the risk only show up with everything together?" |
| **L4 · exploratory** | a person with heuristics, no fixed script (`qa/references/exploratory-session.md`) | a session | "does this depend on human judgment to be noticed?" |

L4 **cannot be automated by definition** — it is where you discover what will become a scenario in
L0–L3, or what stays `manual-permanent` in the catalog. A scenario born from exploration enters with
`origin: exploratory` and gets a target level between L0 and L3.

## The rule: argue for going down

When automating, ask **"which part of this scenario justifies the requested level?"**. Almost always
the scenario is a domain rule (L0) dressed up as a screen flow. In that case:

- propose the lower level **with the sentence saying why** ("the outstanding balance is a domain rule:
  L0 proves the block; the screen only shows what the rule decided");
- also say **the loss** — going down trades fidelity for speed and stability. Name what stops being
  covered ("nobody proves the button calls this use case");
- if the team wants the visual coverage anyway, **split it in two**: L0 proves the rule, L3 only
  proves that the screen shows the result — the L3 stays small, fast and stable.

**Do not go down** when the real risk is in the seam: payment, session/authentication, navigation
across domains, cache/CDN, data migration, and anything that already broke in production there. A
change that crosses repositories calls for **L2** — cheaper than E2E, and it catches the break before
the other side merges (`preflight/references/contract-testing.md`).

## Signs of the wrong level

- **E2E that mocks the backend** → it was L0/L1 in disguise.
- **Unit test with 5 chained mocks** → it was L1: the value is in the real dependency.
- **L1 that starts the whole system to prove one rule** → it was L0.
- **E2E suite nobody runs before merge** → too expensive a level for the frequency: go down, or
  shrink the scenario's scope.
- **A test that breaks on every refactor with no bug at all** → it is tied to the implementation, not
  to the behavior.

## Where the level lives

In the catalog (`target_level`, in `qa/references/scenario-catalog.md`), decided at refinement
(`test-strategy`) and revisited at automation (`qa-spec`). Changed level? Update the catalog with the
reason — the history of those changes is what shows the team learning to test more cheaply.
