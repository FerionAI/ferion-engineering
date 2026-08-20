# Choosing the right model for each part of the task

Do not use a frontier model to rename a variable, or a small one to design a critical architecture.
Model choice is the largest cost lever available, and the easiest one to get wrong in both directions.

## By task type

| Task | Tier | Why |
|---|---|---|
| Rename, mechanical refactor, formatting | small/fast | no reasoning involved |
| Reading and summarizing a file, extracting data | small/fast | comprehension, not judgment |
| Writing tests for existing behavior | mid | needs to understand the code, not design it |
| Implementing a well-specified task | mid | the spec did the hard thinking |
| Architecture, design decisions, trade-offs | strong | this is where a wrong call costs weeks |
| Debugging something non-obvious | strong | hypothesis generation is exactly what the tier buys |
| Independent verification / adversarial review | strong | a weak verifier approves what a strong author got wrong |
| Reviewing security-sensitive code | strong | the failure mode is expensive and silent |

## The rule: start cheap, escalate on demand

Begin with the cheaper tier. If the answer comes back shallow, wrong or hedged, escalate — you paid
for one cheap attempt, not for the whole task at the expensive tier. The inverse (starting strong
everywhere) is the most common waste in agentic work.

The exception: **do not economize on verification.** The verification step is the one that catches the
error the author could not see; a cheap verifier defeats its own purpose
(`preflight/references/anti-hallucination.md`).

## Reasoning effort

Where the harness exposes an effort/thinking level, treat it as a second dial:

- **Low** — mechanical work, well-specified edits, extraction.
- **Medium** — the default for implementation.
- **High** — architecture, debugging, adversarial verification, anything where being wrong is expensive.

Effort is cheaper to raise than model tier for a single hard step. Try the dial before the tier.

## Caching

Long conversations reuse the same prefix. Keeping the stable context stable (system prompt, the files
you already read) and appending rather than rewriting is what makes cache hits happen — and cache
reads cost a fraction of fresh input. Concretely: do not re-read files to "refresh" them, and do not
restructure the conversation when appending would do.

## Measuring whether you got it right

`cost` records tokens and USD per issue. If the median cost of a class of task is out of line with its
complexity, the model choice is usually why. That is the signal to tune with — not intuition about
which model "feels better".

> Model names and prices move faster than this document. Check the current lineup rather than trusting
> a hardcoded list, and keep the *shape* of the decision (cheap for mechanical, strong for judgment)
> which does not change.
