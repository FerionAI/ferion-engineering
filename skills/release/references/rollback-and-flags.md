# Rollback, feature flags and risky changes — the checklist

The rule behind all of this: **decide how you will undo it before you do it.** A rollback plan
invented during an incident is not a plan.

## The risky-change checklist

Run it in the `plan` step (`spec-flow`), not at deploy time.

- [ ] **What is the blast radius** if this is wrong? (one endpoint / one service / everything)
- [ ] **Is it reversible?** If not, say so explicitly and get a human decision.
- [ ] **Rollback criterion:** the objective number that triggers reverting (error rate > X%, p99 > Y,
      a specific alert).
- [ ] **Rollback mechanics:** the exact command or action, tested at least once, not theorized.
- [ ] **Who is watching**, for how long, and where (which dashboard).
- [ ] **Is data involved?** → expand/contract, backup taken, backfill idempotent.
- [ ] **Is a contract involved?** → versioned, consumers migrated or compatible
      (`fullstack/references/api-versioning.md`).
- [ ] **Communication:** who needs to know before, and who needs to know if it goes wrong.

## Rollback: the fast options, in order

1. **Turn the flag off** — seconds, no deploy, no build. This is why flags exist.
2. **Redeploy the previous version** — minutes. Requires that the previous artifact still exists and
   that the change was backward compatible.
3. **Roll forward with a fix** — only when 1 and 2 are impossible (usually because a migration made
   the old code unable to read the new data). Slowest and riskiest; avoid designing yourself into it.
4. **Restore data from backup** — the last resort. Have you ever tested the restore? A backup nobody
   has restored is a hypothesis.

## Feature flag lifecycle

A flag is a fork in the code. Two forks is a branch; twenty is a maze nobody can reason about.

| Stage | Rule |
|---|---|
| **Create** | it has an owner, a purpose and a **removal date** written down at creation |
| **Roll out** | by percentage/cohort/environment, with the kill switch verified |
| **Full** | once at 100% and stable for a while, it is dead weight |
| **Remove** | delete the flag **and the dead branch**. This is the step everyone skips |

An old flag is debt with interest: it makes every subsequent change harder to reason about, and it
eventually gets flipped by accident. Track removals as issues from the day the flag is created.

**Never nest flags.** Two flags controlling the same flow means four states, of which you tested two.

## Data migration — expand/contract

```
1. EXPAND    add the new column/field, nullable, alongside the old
2. WRITE     new code writes both; old code keeps working
3. BACKFILL  migrate the history in idempotent, resumable batches
4. READ      new code reads the new field
5. CONTRACT  only when nothing reads the old one, remove it
```

Each step is a separate deploy, and each one is individually reversible. Doing 1–5 in a single
release is exactly how you end up needing a backup restore.

Backfill rules: idempotent (running it twice is safe), resumable (it will be interrupted), batched
(do not lock the table), observable (you can see progress), and **no PII in the migration logs**
(`privacy`).
