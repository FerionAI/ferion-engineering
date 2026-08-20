# Incident runbook

The sequence to follow when something is on fire. Print it, or at least know where it is — the middle
of an incident is not the time to design a process.

## Severity (decide in the first minute)

| Sev | Impact | Response | Communication |
|---|---|---|---|
| **SEV1** | service down, data loss, PII exposure | everything now, all hands | leadership + external if customers affected |
| **SEV2** | serious degradation, no workaround | immediate | internal, updates every 30 min |
| **SEV3** | partial, with a workaround | business hours, prioritized | the affected team |
| **SEV4** | cosmetic or latent risk | becomes a normal issue | the issue itself |

When in doubt between two levels, take the higher one. Downgrading later is free; upgrading late is
not.

## The first 15 minutes

```
0–2 min    Declare. Channel, severity, name the IC. One source of truth for status.
2–5 min    What changed? Last deploy, last flag, last migration, last config change.
           Most incidents are a change. Check that before theorizing.
5–10 min   MITIGATE. Flag off, or roll back (`release`). Do not diagnose first.
10–15 min  Confirm with metrics that the pain stopped. Communicate.
```

**Mitigate before diagnosing.** The instinct to understand first is the single biggest driver of
MTTR. You can understand it perfectly at 4pm; the users need it working at 2:15.

## Roles

- **Incident commander** — coordinates, decides, communicates status, **does not touch the code**.
  The most common failure mode of a small team is that the only person who can fix it is also trying
  to run the incident.
- **Ops** — investigates and mitigates.
- **Comms** — updates stakeholders on a fixed cadence, even with no news.

One person can wear all three hats, but say out loud which one you are wearing.

## Investigating (after mitigation)

1. **The change.** Deploys, flags, migrations, config, dependency updates — in the window.
2. **The signals.** Error rate, latency, saturation, traffic (the four golden signals). Where did the
   curve bend, and what happened at that moment?
3. **The blast radius.** One endpoint, one service, one region, everything?
4. **Correlate.** Trace id from an error → the full request path. Logs without a correlation id are
   the reason this step takes an hour instead of five minutes.

## Communication template

```
[SEV2] Checkout intermittently failing
Status: investigating | mitigating | monitoring | resolved
Impact: ~15% of checkout attempts failing since 14:05 UTC
Action: rolling back the 14:02 deploy
Next update: 14:40 UTC
```

Fixed cadence, even when there is nothing new. Silence is what makes stakeholders start asking
individual engineers for updates, which is how the response falls apart.

## Closing

- Confirm stability with metrics, not with hope. Watch for at least one full traffic cycle.
- Downgrade the severity before closing.
- **SEV1/SEV2 → postmortem** (`postmortem.md`) within a few days, blameless, with action items as
  issues.
- Whatever would have caught it earlier goes into `preflight` or into monitoring.
