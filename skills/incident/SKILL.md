---
name: incident
description: Production incident response and blameless postmortem — detect, classify severity, mitigate (rollback/flag), communicate, find the root cause and learn without blaming. Use when "production is down", "it's off the air", "we have an incident", "mass errors / error spike", "a customer reported it stopped", "open an incident", "write a postmortem/RCA", or after mitigating to record the learning. A personal data leak is also an incident (it triggers the privacy path). MCP-first (observability to investigate; GitHub issues for the action items).
---

# incident — response and blameless postmortem

Two goals at once: **restore the service fast** (lower MTTR — DORA) and **learn without blame** so it
does not repeat. Golden rule: **mitigate before diagnosing** — stop the pain first (rollback/flag),
understand afterwards. And **never blame a person**: the target is the system or process that let the
error through.

## 1. Detect and classify (severity)

Alerts from observability (`integrations`), a customer report, or an error/latency spike. Classify to
size the response:

| Sev | Impact | Example | Response |
|---|---|---|---|
| **SEV1** | Critical — service down / data loss / PII exposure | checkout down, corrupted database | everything now, leadership informed |
| **SEV2** | Serious — heavy degradation, no workaround | intermittent login, high latency | immediate response |
| **SEV3** | Moderate — partial, with a workaround | one broken feature | during business hours, prioritized |
| **SEV4** | Low — cosmetic / latent risk | rare error with no impact | becomes a normal issue |

## 2. Roles (even if it is one person)

- **Incident commander (IC):** coordinates, decides, does not touch the code. **Ops:** investigates
  and mitigates. **Comms:** updates stakeholders. On a small team the same person wears all the
  hats — but name the IC anyway.

## 3. Respond (stop the pain)

1. **Declare** the incident (dedicated channel, severity, IC). One source of truth for the status.
2. **Mitigate now:** **turn the feature flag off** or **roll back the deploy** (`release`) —
   reverting is almost always faster than fixing. Stop the bleeding before investigating.
3. **Communicate** at fixed intervals (even "no news") — internally, and externally if customers are
   affected.
4. **Stabilize** and confirm with metrics that the pain is gone. Only then close the response phase.

## 4. Root cause (not the symptom)

With the service stable, investigate the **root cause** (`spec-flow` for the fix) — and fix it where
**all callers** pass through, not just the path that showed up. Guards and tests that would have
caught it go into `preflight` so the error cannot come back.

## 5. Blameless postmortem (mandatory for SEV1/SEV2)

Write it following `references/postmortem.md`: timeline, impact, root cause, what helped and what got
in the way, and **action items with an owner and a date** — each one becomes a **GitHub issue**
(`issues`). **Blameless:** describe what the system or process allowed, never "so-and-so made a
mistake". Blame hides the real cause.

## Incident involving personal data

Leaking or exposing PII is both an incident **and** a privacy event: notify the data protection
contact and follow `privacy` (`privacy/references/data-map-and-checklist.md`) — contain, assess the
scope; the decision to notify the regulator or the data subjects belongs to that contact and legal,
not to engineering. Record it in the postmortem.

## In the flow

- **`start`:** "production is down / error in prod / open an incident" lands here.
- **`release`:** the mitigation (rollback/flag) and the revert criterion come from there.
- **`integrations`:** logs/metrics/traces for the investigation. **`issues`:** action items.
- **`health`:** the incident's MTTR and change failure rate feed the DORA metrics.
- **Runbook and severity:** `references/runbook.md`; **first response by type** (bad deploy, queue/DLQ
  backlog, failed migration, unhealthy pod, external dependency, PII leak):
  `references/runbooks-by-type.md`. **Postmortem:** `references/postmortem.md`.
