# Tool — verify in production + the QA gate

Two things that close the QA cycle: confirming something works (or reproducing a problem) with real
signals, and giving the "can ship / cannot ship" verdict.

## Verify / reproduce with real signals

Through the MCPs (`integrations`):

- **Observability:** logs, traces and metrics for the flow/service — confirm the error is gone after
  the fix, or find the trace of a failure. Correlate by trace id.
- **Session analytics:** a recording or heatmap to reproduce the user's behavior.
- **Product analytics:** did the funnel/conversion move as expected after the delivery?

Use this to validate a hotfix, investigate an intermittent bug and confirm the impact of a fix.

## The QA gate (approve / reject)

Before closing the issue, run the **Definition of Done** (`constitution`) as a gate:

- [ ] All acceptance criteria met (with evidence).
- [ ] P0/P1 test cases passing; relevant regression ok (`risk-and-regression.md`).
- [ ] No open blocking bug.
- [ ] Security (OWASP) and privacy checked where applicable.
- [ ] Front end: design system, WCAG 2.2 AA accessibility, Core Web Vitals ok.
- [ ] Observability present (you can actually see it in production).

**Verdict:**
- ✅ **Approved** — criteria met, nothing blocking. Record it on the issue.
- ❌ **Rejected** — list objectively what is missing (bug/criterion), with evidence, **on the issue**.

## Failed twice? The correction mode changes (hard rule)

A **second rejection of the same issue** is not "one more bug": it is a signal that the first fix
treated the symptom QA pointed at, not the rule. The classic shape: "an unpublished item is still
counted" comes back in a different endpoint, one at a time.

From the second round onward, fixing it the same way is forbidden. The fix only ships with all three:

1. **Name the rule, not the case.** Write the invariant on the issue ("an unpublished item counts
   toward neither progress nor eligibility"), not "fixed in endpoint X".
2. **Sweep the siblings.** `grep` every place that applies (or should apply) that rule — other
   endpoints, other screens, the same calculation copy-pasted. Fix them all in the same PR, or open
   the issues and link them. The cheap fix is the one that closes the whole class, not the one that
   closes the ticket.
3. **A test that fails first.** A test of the invariant (not of QA's screenshot) that fails on the
   current code and passes after. Without it, the third round is a matter of time.

And close the loop: if the rule was not in the issue's **state matrix**, it goes in there
(`epic/references/issue-template.md`) — the rejection becomes a refinement lesson, not just a fix.

## Write-back (always)

The verification result and the gate verdict live **on the issue** — it is the source of truth. Never
approve or reject only in the chat.
