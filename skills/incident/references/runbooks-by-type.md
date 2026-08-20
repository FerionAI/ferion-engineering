# First response by incident class

The general runbook is in `runbook.md`. These are the first moves for the classes that actually
recur — each one starts with the fastest mitigation, not with the diagnosis.

## Bad deploy (the most common incident by far)

**Signal:** errors or latency jump within minutes of a deploy.

1. **Roll back first.** The previous version is known-good; the new one is a hypothesis.
2. Confirm the curve returns. Only then look at the diff.
3. If the rollback does not fix it, the deploy was probably coincidental — widen the search
   (dependency, data, traffic).
4. **After:** why did CI and `preflight` not catch it? That answer becomes a checklist rule.

## Feature flag gone wrong

**Signal:** errors start at a rollout percentage change, not at a deploy.

1. **Kill switch.** Turn the flag off — it is faster than any deploy.
2. Check whether the flag left data in an inconsistent state (half-migrated records, partial writes).
3. **After:** the flag needed a test at 100% in staging, not just at 0%.

## Queue / DLQ backlog

**Signal:** consumer lag growing, the dead-letter queue filling.

1. **Do not purge the DLQ.** Those are unprocessed events, i.e. lost work.
2. Is the consumer down, slow, or failing on a poison message? Read one failed message.
3. Poison message → fix or quarantine that one; consumer slow → scale out; consumer broken → roll back.
4. **Replay the DLQ** only after the cause is fixed, and only if the consumer is idempotent. If it is
   not, that is the real incident.

## Failed migration

**Signal:** the deploy is stuck, or the app is up but errors on a table.

1. **Is it partially applied?** This is the dangerous state. Check before doing anything else.
2. Expand/contract migration → rolling back the code is usually safe (the old code still reads the
   old shape). A destructive migration → **do not roll back blindly**, you may lose data.
3. Restore from backup only as the last resort, and with someone else watching.
4. **After:** the migration was not expand/contract, or was not tested against a production-sized
   dataset.

## Unhealthy service / pods restarting

**Signal:** restart loop, health check failing, memory or CPU saturation.

1. Recent deploy? Roll back. No deploy? Look at resource limits and traffic.
2. OOM kill → memory leak or a limit too low; check the trend, not the instant.
3. Failing health check → is the check itself testing a downstream dependency? A health check that
   depends on another service turns one outage into a cascade.
4. Scale up to buy time, then fix. Buying time is legitimate mitigation.

## External dependency down

**Signal:** errors concentrated on calls to one third party.

1. **Is there a circuit breaker?** If not, that is the finding — one slow dependency is exhausting
   your connection pool and taking down unrelated endpoints.
2. Degrade gracefully: cache, queue for later, or a clear message to the user. Failing the whole
   request because a non-critical enrichment call timed out is a design bug.
3. Check the provider's status page; communicate the ETA you do not control.

## Personal data exposure

**Signal:** data visible to the wrong user, an unprotected endpoint, a leaked export.

1. **Contain first:** close the access, revoke the credential, take the endpoint down. Losing
   availability beats extending the exposure.
2. **Do not delete the evidence** — logs are needed to scope who accessed what.
3. **Notify the privacy contact immediately** (`privacy`). Scope, notification decisions and
   regulator timelines are theirs, not engineering's — and the clock may already be running.
4. Postmortem is mandatory regardless of severity level.
