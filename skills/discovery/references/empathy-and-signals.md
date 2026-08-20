# Empathize — the signals you already have

Before talking to anyone, read what the product already told you. Most teams are sitting on months of
behavioral evidence they have never looked at.

## Where the signal is

| Source | Answers | Watch for |
|---|---|---|
| **Session analytics** (recordings, heatmaps) | what people actually did | rage clicks, dead clicks, sharp drop-off on one step |
| **Product analytics** (funnels, events) | how many, and where they leave | the step with the worst conversion; the segment that behaves differently |
| **Support tickets / bug issues** | the pain people bothered to report | recurring themes, not individual tickets |
| **In-app onboarding** | where new users get stuck | steps skipped, guides abandoned |
| **Search queries inside the product** | what people cannot find | queries with no results |

The last one is the most underused: a list of internal searches that returned nothing is a list of
features people expect you to have.

## Reading it honestly

- **A funnel drop is a question, not an answer.** 60% leave at payment — because the form is bad,
  because the price is wrong, or because they were never going to buy? The quantitative source found
  the *where*; you still need the *why*.
- **Watch five recordings before theorizing.** Reading a number produces a hypothesis; watching
  someone fail produces understanding. It takes twenty minutes.
- **Segment before concluding.** An average hides the two populations it is made of. New vs returning,
  mobile vs desktop, the plan tier — one of those splits usually explains the whole thing.
- **Survivorship bias.** Your data only describes people who got far enough to be measured. The ones
  who bounced at the landing page are invisible and may be the real story.

## The empathy brief (the output)

Half a page. It becomes the what/why of the spec.

```markdown
## Who suffers
<persona / job to be done — specific, not "the user">

## The pain
<what they are trying to do and what gets in the way>

## The evidence
- <number, with the source and the window>
- <a quote or an observed behavior from a recording/ticket>

## What we do not know
<the honest gaps — what a real conversation would answer>
```

**"What we do not know" is the most valuable section.** Without it, a brief made of proxies reads as
a brief made of facts, and the team builds on it as if it were.

## Guardrails

- **Evidence over opinion.** "I think users want…" is a hypothesis; label it as one.
- **No data access?** Say the brief is based on hypotheses to validate, and continue — do not stall,
  and do not dress the assumption up as a finding.
- **No PII in the brief** (`privacy`). Quote behavior, not people: "a user on a mobile plan", not the
  email address.
- **Analytics is a proxy for the user, not the user.** It tells you what happened, never what they
  wanted. That is what `usability-testing.md` is for.
