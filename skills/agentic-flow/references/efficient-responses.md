# Efficient responses and token consumption

Maximum signal per token. This is about the agent's own behavior — how it reads, how it works and how
it answers.

## Reading (where most tokens go)

- **Progressive disclosure.** Load the SKILL.md; load a `references/` playbook only when the moment
  calls for it. That is the whole reason this plugin is structured in two layers.
- **Never re-read what you already read.** The file is in context. Re-reading it to "make sure" is
  pure cost with no information gain — and if it changed, the tool that changed it would have said so.
- **Read the part, not the file.** When you know you need lines 40–80, read lines 40–80.
- **Search before reading.** `grep`/`glob` to locate, then read the hits. Reading a directory to find
  something is the expensive way to run a search.
- **Manifests and samples, not the whole codebase.** `onboard` is built on this rule: detect the stack
  from `package.json`, not from reading every file it lists.

## Working

- **Batch independent tool calls** into one turn. Three greps that do not depend on each other go
  together, not in three round trips.
- **Do not narrate what you are about to do** before doing it. Do it, then say what happened.
- **Do not re-derive settled facts.** Something established earlier in the conversation stays
  established; re-checking it is a round trip that buys nothing.
- **Do not re-query state a hook already injected.** The session banner carries the flow status;
  running `flow-gate.sh status` again re-reads the whole context to show what is already there. Run
  it only when the banner is missing (`/clear`, a summarized context).
- **Do not search for constants.** A plugin script's path, a marker's format, a field id: the skill
  states them. A `find` over the plugin folder is a round trip spent rediscovering a fixed value.
- **One call for what a script runs in one.** Build, types, lint and tests are `preflight.sh`, not
  four calls; split only to debug one specific failure.

## Answering

**Terse by default.** High signal, zero filler, no preamble, no recap of what the user just said, no
summary of what they can see in the diff.

| Instead of | Write |
|---|---|
| "Great question! Let me look into that for you." | (nothing — just answer) |
| "I've now completed the implementation of the feature you requested, which involved…" | "Done. Added `x` in `a.ts:42`; test in `a.test.ts`." |
| A 300-word explanation of a 3-line change | The 3-line change |
| Listing the options you decided against | The decision, with one line of why |

**Closing a step is up to 3 lines + the link** (PR/issue). Prose is not spread evenly: a small share of
messages — the end-of-step reports — carries most of the text. Whoever wants the detail asks.

**But terseness is not skipping clarification.** When something essential is missing, ask — **one at
a time when the answer changes the next question, together when they are independent**. A dumped
questionnaire is bad, but three independent questions in three rounds cost three human waits. Saving 200 tokens by guessing and building the wrong
thing costs the whole task (P1).

**And requested explanation is not debt.** If someone asks for a report, a walkthrough or the
reasoning, give it in full. The rule is against unrequested prose, not against answering the question.

## The shape of a good delivery message

```
[what changed, one line per file that matters]
[anything the person needs to decide or know]
[what you deliberately did not do, if it was in scope]
```

No headers, no bullet lists of things they already know, no "next steps" they did not ask for.

## Where the cost actually goes

Spend is `round trips × context size`, not words. Every call re-sends the whole context, so:

| Where it goes | Order of magnitude |
|---|---|
| Context re-reads (cache read) | almost all of the tokens |
| Thinking | a large share of the output |
| **Prose for the person** | **around one percent** of the output |
| Time | split between generating and running tools — and every call pays both |

The practical consequence: **every call avoided saves a whole context re-read**; every paragraph cut
saves almost nothing in money (it saves reading). Optimize calls first, words second. Do not take
these proportions on faith — measure your own sessions (below).

## How to measure

- **Round trips per issue** — `session-cost.py` reports `requests`, and it goes into the issue's
  cost marker (`cost`). It predicts time and dollars better than a raw token count.
- **Per skill** — `python3 ${CLAUDE_PLUGIN_ROOT}/skills/cost/scripts/skill-profile.py`: calls,
  minutes and tokens per skill, plus the share of context re-reads and of prose, from the local
  transcripts. It says **what** to optimize.
- Fewer tokens per PR (compare before/after on typical tasks), and time to the first useful result
  (not to the "final report").

## Model and context

- **Model proportional to the task** (`model-selection.md`) — the single biggest cost lever.
- **Minimal context scope.** Do not pull the whole repo into context to change one function.
- **Subagents isolate context** (`agent-orchestration.md`): a subagent that reads 50 files returns
  one paragraph, and the 50 files never enter your context. That is often the cheaper path, not the
  more expensive one.
