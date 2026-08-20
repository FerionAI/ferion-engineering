# Reviewing an infrastructure change (Terraform/IaC)

An application bug affects a request. An infrastructure bug affects everything at once, and the
"undo" may not exist. The review is different: the artifact you review is the **plan**, not the diff.

## Rule #1 — read the plan, not just the code

The `.tf` diff shows intent; the `terraform plan` shows what will actually happen. A three-line change
can produce a `destroy` you did not intend.

```bash
terraform init && terraform plan -out=tf.plan
terraform show -no-color tf.plan   # attach this to the PR
```

**In the plan, look for these first:**

| Signal | Why it matters |
|---|---|
| `must be replaced` / `forces replacement` | the resource is destroyed and recreated — data loss on a database, downtime on anything |
| `destroy` on anything stateful | a database, a bucket, a volume, a DNS zone |
| Unexpected changes to resources the PR does not mention | drift, or a module bumped underneath you |
| An empty plan when you expected changes | you are pointed at the wrong workspace/state |
| A huge plan for a small change | a provider or module version bump came along for the ride |

## Blast radius

Before approving, answer: **what breaks if this is wrong?** Scope the answer honestly — a security
group rule can take down every service in the VPC.

- Is the change scoped to one environment, or does the module feed all of them?
- Is it reversible? A deleted bucket with no versioning is not.
- Is there a maintenance window, or does it apply at 3pm on a Friday?

## The checklist

- [ ] **Clean plan** — no unexpected drift; the plan output is attached to the PR.
- [ ] **No `destroy`/replacement of a stateful resource** without an explicit, acknowledged plan.
- [ ] **State isolated per environment**, with a locking backend; no shared state across environments.
- [ ] **No secret in the state or in a committed `.tfvars`** — secrets through a secret manager
      (`secrets.md`). Remember the state file contains resolved values.
- [ ] **Versions pinned** — provider and module versions constrained, so the plan is reproducible.
- [ ] **Apply discipline** — it is documented who applies and how (CI with OIDC, or a named human).
- [ ] **`pre-commit` on the modules** (`terraform_fmt`, `tflint`, `validate`, `docs`).
- [ ] **Tags/labels** applied (owner, environment, cost center) — this is how you find the orphan
      resource in six months.
- [ ] **Least privilege** on the IAM being created; no wildcard action on wildcard resource.

## Degradation

Cannot run the plan (no credentials, backend unreachable)? **Say so and do not approve as if you
had.** An IaC review without a plan is a code review, not an infrastructure review — label it that way
and let a human with access decide.
