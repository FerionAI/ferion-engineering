# Blameless postmortem — template

Mandatory for SEV1/SEV2, within a few days of the incident while memory is fresh. Its purpose is to
change the system, not to find who to blame. Published where the team can read it.

```markdown
# Postmortem — <short title>

**Date:** <when it happened>   **Severity:** SEV<n>   **Duration:** <detection → resolution>
**Author:** <name>   **Incident commander:** <name>   **Status:** draft | reviewed

## Impact
<Who was affected, how many, for how long, what they could not do. In user terms, with numbers:
"~4,300 users could not complete checkout for 47 minutes", not "the service degraded".>

## Timeline (UTC)
| Time | Event |
|---|---|
| 14:02 | the change was deployed |
| 14:09 | the error-rate alert fired |
| 14:11 | incident declared, IC assigned |
| 14:18 | rollback started |
| 14:26 | error rate back to normal |
| 14:49 | confirmed stable, incident closed |

Include **detection time** (event → someone knew) and **mitigation time** (knew → pain stopped)
separately. They have different fixes: the first is monitoring, the second is tooling.

## Root cause
<What actually caused it — the technical chain, and the systemic reason it was possible.
Keep asking "why did that happen?" until you reach something you can change.>

## Contributing factors
<What made it worse or slower: a missing alert, a runbook that was out of date, an unclear
dashboard, an alert that fires so often nobody reads it.>

## What went well
<Genuinely — the fast rollback, the alert that did fire, the person who noticed. This is not
padding: it tells you which investments to keep.>

## What went badly
<Systems and processes, never people.>

## Action items
| # | Action | Type | Owner | Due | Issue |
|---|---|---|---|---|---|
| 1 | Add an alert for <x> | detection | @a | <date> | #501 |
| 2 | Make <y> idempotent | prevention | @b | <date> | #502 |
| 3 | Update the <z> runbook | response | @c | <date> | #503 |
```

## The rules that make it work

**Blameless means blameless.** Write "the deploy pipeline allowed a change with no canary" — never
"X deployed without testing". A person acted reasonably given the information and tooling they had;
if the outcome was bad, the system let it be bad. The moment postmortems assign blame, people stop
reporting incidents, and you lose the data entirely.

**Every action item is a real issue** with an owner and a date (`gh issue create`), linked in the
table. An action item with no issue is a wish. Review them at the next retro — an unfinished action
item from a previous postmortem is itself a finding.

**Prefer prevention over "be more careful".** "Be more careful" is not an action item. A guard, a
test, an alert, a default changed, a step removed — those are.

**Ask what would have caught it earlier.** The answer usually belongs in `preflight` (a rule that
would have blocked the PR) or in monitoring (an alert that would have fired at 14:03 instead of
14:09). Feed it back there.
