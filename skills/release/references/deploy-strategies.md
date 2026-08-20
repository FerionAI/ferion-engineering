# Deploy strategies

Pick by blast radius, not by fashion. The strategy's whole job is to make the failure small and the
recovery fast.

## The four

| Strategy | How it works | Use it when | Cost |
|---|---|---|---|
| **Rolling** | replicas replaced gradually | the default for a reversible change | old and new run simultaneously — the change must be backward compatible |
| **Canary** | a % of traffic on the new version, observed, then ramped | you want production signal before full exposure | needs traffic splitting + metrics per version |
| **Blue-green** | full new environment, then switch routing | instant switch and instant revert matter | double the infrastructure during the switch |
| **Behind a flag** | deployed off, enabled later | a big or uncertain feature | flag lifecycle to manage (`rollback-and-flags.md`) |

**Rolling and canary both mean two versions run at once.** Every change must therefore be backward
compatible with the previous version for the duration of the rollout — the same expand/contract rule
that applies to data.

## Canary that actually protects you

A canary with no automated abort criterion is just a slow deploy.

1. **Define the criterion before shipping:** error rate, p99 latency, a business metric.
2. **Compare against the baseline**, not against an absolute — the new version's error rate vs the
   current one, on the same window.
3. **Give it enough traffic and enough time.** 1% for two minutes proves nothing; you need a sample
   that would show the regression.
4. **Automate the abort.** If a human has to notice, the canary is a dashboard.
5. Ramp: 1% → 10% → 50% → 100%, holding at each step.

## Environments

`development → staging → production` is the common shape. Two rules that matter more than the names:

- **Nothing reaches production without the human gate in staging** (`qa`) — the pipeline can be fully
  automated up to that point and should stop there.
- **Staging must be close enough to production to be meaningful.** A staging environment with a
  different runtime version, different data volume or a mocked dependency will pass things production
  rejects (see the environment consistency block in
  `preflight/references/preflight-checklist.md`).

## Deploy ≠ release

Deploying puts the code in production. Releasing exposes the behavior to users. Separating them (with
a flag) is what makes a large change safe: you deploy on Tuesday with nobody affected, and turn it on
Wednesday morning with everyone watching.

## Before any deploy

- [ ] Rollback criterion and mechanics written down (`rollback-and-flags.md`).
- [ ] Alerts and dashboards ready **before**, not after — a silent deploy is a blind deploy.
- [ ] The change is backward compatible for the rollout window (two versions coexist).
- [ ] Data migration, if any, is expand/contract and reversible.
- [ ] Someone is watching for the first N minutes. "Deploy and go to lunch" is how a 5-minute incident
      becomes a 90-minute one.

## Cross-repo

When the change spans repositories, the **order between them** is coordinated in `workspace`
(back end before front end, producer before consumer); `release` handles each service's own deploy.
