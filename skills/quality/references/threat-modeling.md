# Lightweight threat modeling (30 minutes before coding a sensitive flow)

Not a security ceremony — a half-hour conversation that catches design flaws no linter can. Run it in
the `plan` step of `spec-flow`, before the code exists.

## When it is worth it

Run it when the flow touches: authentication or authorization, payment, personal data, file upload,
anything an external party can call, or anything whose failure is irreversible (deleting data,
sending money, sending mail to users).

Skip it for an internal refactor, a copy change, a new report over data you already expose.

## The four questions

Draw the flow (boxes and arrows is enough — who calls what, where the data crosses a trust boundary),
then answer:

**1. What are we building?** — the data flow diagram. Mark every **trust boundary**: browser →
API, service → service, your system → a third party. Everything crossing a boundary is untrusted.

**2. What can go wrong?** — walk STRIDE against each element:

| | Threat | Ask |
|---|---|---|
| **S** | Spoofing | can someone pretend to be another user or service? |
| **T** | Tampering | can the request/data be modified in flight or at rest? |
| **R** | Repudiation | can someone deny having done it? is there an audit trail? |
| **I** | Information disclosure | what leaks in errors, logs, responses, timing? |
| **D** | Denial of service | what is expensive and unthrottled? |
| **E** | Elevation of privilege | can a normal user reach an admin path? |

**3. What are we going to do about it?** — for each real threat: mitigate, accept (with a recorded
reason), or transfer. A mitigation becomes an acceptance criterion on the issue, not a good intention.

**4. Did we do a good job?** — the mitigations have tests; the accepted risks are written down in
the plan or an ADR.

## The output (keep it small)

Add to `specs/<feature>/plan.md`:

```markdown
## Threat model
Trust boundaries: <browser→api, api→payment-provider>
| Threat | Type | Mitigation | Where |
|---|---|---|---|
| Another user reads order N | Elevation | ownership check in the query | AC #3 + test |
| Card data in the log | Disclosure | field allowlist in the logger | AC #5 |
| Unlimited retries on the coupon | DoS | rate limit per user | accepted for v1 — issue #88 |
```

Three rows are a successful threat model. Twenty rows means you modeled the whole system instead of
the flow.

## The failure mode to avoid

The most common outcome of threat modeling is a document nobody reads. That is why the output here is
**acceptance criteria on the issue**, not a separate artifact: a threat with no test is a threat you
did not mitigate.
