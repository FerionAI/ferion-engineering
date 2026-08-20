# Tool — test cases from the issue

The acceptance criteria are the target. This turns them into cases someone can execute (or automate)
without guessing.

## The method

1. **Read the issue** (`gh issue view <n> --comments`): acceptance criteria, state matrix, scope and
   non-scope.
2. **One case per criterion**, minimum. A criterion with no case is a criterion nobody will check.
3. **Then the state matrix** — each row of the matrix (`epic/references/issue-template.md`) is a case.
   This is where the defects actually are: not in the happy path, in the "what if the item is
   unpublished / the access expired / the list is empty".
4. **Then the error paths** — invalid input, missing permission, the dependency is down, the timeout.
5. **Prioritize:** P0 (blocks release), P1 (important), P2 (nice to have). Test P0/P1 before shipping;
   P2 when there is room.

## The format

```
ID: <issue>-01   Priority: P0   Type: functional | negative | edge | a11y
Preconditions: <the state the system must be in>
Steps:
  1. <action>
  2. <action>
Expected: <observable, specific result — not "it works">
Evidence: <screenshot / log / query>
```

Two rules that make cases useful instead of decorative:

- **Expected results are observable.** "The order appears in the list with status Paid" — not "the
  order is processed correctly".
- **Preconditions are reproducible.** If setting up the state takes 20 manual clicks, the case will be
  skipped. Seed it (`context/references/seed-and-environments.md`).

## Coverage checklist

- [ ] Every acceptance criterion has at least one case.
- [ ] Every row of the state matrix has a case.
- [ ] The main error paths are covered (not just the happy path).
- [ ] Permissions: at least one case with the wrong user (the authorization bug is the expensive one).
- [ ] Empty / one / many, for anything that renders a list.
- [ ] Accessibility on the flow, if there is UI (`ux-a11y-qa.md`).

## Where they live

On the issue, as a comment — the issue is the source of truth. What repeats every release becomes
automation (`automation.md`); what is exploratory does not become a case at all (`exploratory.md`).

**Do not turn every case into an automated test.** A case that runs once, for one release, is cheaper
as a manual check. Automate what repeats and what regresses.
