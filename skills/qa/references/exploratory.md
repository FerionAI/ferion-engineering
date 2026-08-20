# Tool — exploratory testing

Scripted cases verify what someone already thought of. Exploratory testing finds what nobody thought
of — which is where the interesting bugs live. It is structured, not random.

## The session (time-boxed, with a charter)

```
Charter: explore <area> with <resources> to discover <information>
Time-box: 45–90 min (longer than that and attention degrades)
```

Example: *"Explore the checkout flow with a subscription account and expired card data, to discover
failures in error handling and recovery."*

One charter per session. A session with no charter becomes clicking around.

## Heuristics that find bugs

| Heuristic | Try |
|---|---|
| **Boundaries** | 0, 1, many, the maximum, the maximum + 1, empty, very long, negative |
| **Interruption** | close the tab mid-flow, go back, refresh, double-click submit, lose the network |
| **Sequence** | do the steps out of order; do step 2 twice; skip an optional step |
| **Identity** | another user's id in the URL; a lower-privileged account; a logged-out session |
| **State** | the entity in every domain state (expired, unpublished, deleted, still processing) |
| **Data shape** | emoji, RTL text, quotes, `<script>`, 300-character names, other locales |
| **Time** | timezone edges, DST, an expiry that lands during the session |
| **Concurrency** | the same action in two tabs at once |

## While you explore

- **Take notes as you go**, not afterwards: what you did, what you expected, what happened.
- **Follow the smell.** Something looks off but is not clearly broken? That is where to dig — it is
  the reason a human is doing this instead of a script.
- **Do not fix your own path.** When you find something, note it and continue the charter; going down
  the rabbit hole ends the session early.

## After the session

- Bugs found → `bug-report.md`, one issue each.
- **A bug found here that could have been a case → make it a case** (`test-cases.md`), and if it will
  recur, automate it (`automation.md`). This is how exploratory work compounds instead of repeating.
- Note the coverage: what you explored, what you did not get to. That is the input for the next
  session.

## Where it fits

Exploratory testing runs in **staging**, after the scripted cases pass — it is looking for what the
cases did not model, so running it first wastes the session on known ground. It is also the highest
value QA activity you can spend an hour on for a feature with a lot of state.
