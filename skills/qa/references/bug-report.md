# Tool — writing a bug report

A bug report that cannot be reproduced is a conversation, not a bug. The whole value is in someone
else being able to see what you saw.

## The template

```markdown
**What happens:** <the observed behavior, in one sentence>
**What should happen:** <the expected behavior, and where that expectation comes from —
                        acceptance criterion, spec, the rest of the product>

**Steps to reproduce**
1. <precondition: which user, which data, which environment>
2. <action>
3. <action>
→ <what you see>

**Environment:** <env / browser+version / OS / app version or commit>
**Frequency:** always | intermittent (N of M attempts) | once
**Severity:** blocker | high | medium | low
**Evidence:** <screenshot, recording, log excerpt, trace id>
**Related issue:** #<n>
```

Open it with `gh issue create --label type:bug` and link it to the original issue if it came from one.

## What makes it reproducible

- **The precondition is the hard part.** "Log in as a user with an expired subscription and at least
  two orders" is worth more than the three clicks after it.
- **One bug per report.** Two problems in one report means one of them gets fixed and the report gets
  closed.
- **The trace id / correlation id** if you have one — it takes the developer straight to the log.
- **Intermittent?** Say how often, and what was different on the failing attempts. "Sometimes" is not
  data; "3 of 10, always after leaving the tab idle" is.

## Severity vs priority

They are different, and conflating them causes fights:

- **Severity** is technical impact: does it lose data, block the flow, or is it cosmetic?
- **Priority** is business urgency: who is blocked, how many users, is there a workaround?

A cosmetic bug on the signup page can be higher priority than a data bug in an admin tool used twice a
month. State severity; let the product owner set priority.

## Before you file it

- **Is it already reported?** `gh issue list --search "<keywords>" --state all`.
- **Is it actually a bug?** Check the acceptance criteria — behavior that contradicts your expectation
  but matches the spec is a spec discussion, not a bug (and worth having on the issue).
- **No real PII** in the steps, the screenshots or the logs you attach (`privacy`). Reproduce with
  synthetic data where you can.

## After the fix

A bug that reached QA once will try again. When it is fixed, ask for the **regression test** that
would have caught it — and if the same issue fails QA twice, the correction mode changes entirely
(`verify-and-gate.md`).
