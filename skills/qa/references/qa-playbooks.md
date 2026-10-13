# QA playbooks — index

Each playbook is a **sequence with gates and an observable output**, meant to be followed from start
to finish. The judgment ("which level", "does this assertion prove the rule?") lives in the owning
skill; here is only **when to use which**. Playbooks live in the folder of the skill that triggers
them — hence the paths below.

| Playbook | When to use it | Owner |
|---|---|---|
| [`exploratory-session`](exploratory-session.md) | You are about to explore a journey (L4) and want to end with a versioned artifact, not lost knowledge | `qa` |
| [`automate-scenario`](../../qa-spec/references/automate-scenario.md) | A scenario in the catalog leaves `draft` and becomes an automated test | `qa-spec` |
| [`bug-to-regression`](../../bug/references/bug-to-regression.md) | A defect was reported and will become a permanent regression test — **before** fixing it | `bug` |

Your case is not here: the QA kit (`../SKILL.md`) has the tools for test cases, regression, UX/a11y
and the gate; the index of every playbook in the plugin is `PLAYBOOKS.md` (root, auto-generated).
