# Data map and privacy checklist

The data map is a five-minute exercise in the `plan` step that prevents the expensive kind of mistake.
The checklist is what `review` runs.

## The feature's mini data map

Add this to `specs/<feature>/plan.md`:

```markdown
## Data map
| Personal data | Purpose | Legal basis | Where it is stored | Who can see it | Retention | Leaves the system? |
|---|---|---|---|---|---|---|
| email | account identification | contract | users table | the user, support | account lifetime + 6mo | yes — transactional email provider |
| IP address | fraud prevention | legitimate interest | access log | security | 90 days | no |
```

Filling this in answers, before any code exists: do we actually need this field? Do we have a basis
for it? How long do we keep it? Who else gets it?

**The most valuable column is the first one.** Half the time, writing the row is what makes someone
realize the field is not needed at all — and the safest personal data is the data you never collected.

## Classification (what counts)

| Class | Examples | Treatment |
|---|---|---|
| **Identifying** | name, email, phone, national id, address | minimize, encrypt at rest, never in logs |
| **Sensitive** | health, biometrics, race, religion, political views, sexual orientation, union membership | avoid entirely unless the product requires it; stricter basis, stricter access |
| **Behavioral** | pages viewed, clicks, session recordings | still personal data when tied to an identity; mask in recordings |
| **Financial** | payment data | tokenize with the provider; do not store card data |
| **Derived/inferred** | a score, a segment | still personal data — the map covers it too |

## The engineering checklist (run in `review`)

- [ ] **Minimization:** every personal field collected is actually used. No "we might need it later".
- [ ] **Legal basis** identified for each purpose, and the purpose has not silently expanded.
- [ ] **No PII in logs, telemetry or error messages** — masked at the logger, not at the call site
      (a field allowlist beats a blocklist).
- [ ] **Session recording** masks sensitive fields; no screen with visible PII captured.
- [ ] **Analytics** receives no PII as an event parameter; consent respected before firing.
- [ ] **Third parties** receive only the attributes they need, under a data processing agreement.
- [ ] **Access control:** who can read this in production? Least privilege, and audited.
- [ ] **Encryption** in transit and at rest.
- [ ] **Retention** defined, with a purge or anonymization job that actually runs.
- [ ] **Deletion** works end to end — including backups, derived tables, caches, search indexes and
      the analytics warehouse. This is where deletion requests usually fail.
- [ ] **Export** possible in a readable format (portability).
- [ ] **Test data is synthetic** — no production PII in dev, staging, fixtures or screenshots.

## Data subject rights — is it technically possible?

Rights are a legal obligation but an engineering capability. For each, can you do it today, within
the legal deadline?

| Right | The engineering question |
|---|---|
| Access | can you export everything you hold about one person? |
| Correction | can it be corrected everywhere, including derived data? |
| Deletion | does it delete from backups, warehouse, caches, third parties? |
| Portability | in a structured, machine-readable format? |
| Withdraw consent | does processing actually stop, and is the past data handled? |

If the answer to any of these is "we would have to write a script", that is a gap worth an issue
before the regulator or the user finds it for you.

## Incident

A leak or exposure is an incident (`incident`) **and** a privacy event. Contain first, do not destroy
the evidence, notify the privacy contact immediately — notification deadlines are short and start
from the moment of awareness, not from the moment you finish investigating.
