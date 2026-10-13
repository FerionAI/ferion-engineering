# PR report — template

It goes as a comment on the issue and it is what the tech lead reads before deciding. It is short on
purpose: the decision rests on the ❌, not on an account of the review.

```
**Tech lead review — #<n>** · PR <URL> · author @<dev>
**Verdict:** ready for QA | needs changes | blocked
**CI:** green | red (<check>) · **Size:** +<n>/−<n> in <n> files

**Acceptance criteria**
- ✅ <criterion> — <where it is in the diff / the test that proves it>
- ❌ <criterion> — <what is missing>

**Blockers (❌)** — judgment, needs the developer
- `<file>:<line>` — <problem> (<principle P#>). Proposal: <fix>

**Attention (⚠️)** — does not block
- <item>

**Fixed on the branch by the tech lead**
- <short sha> <commit message>

**Questions for the developer**
- <a doubt only the author can answer>
```

Rules:
- An acceptance criterion with no test proving it is ❌ (P2), even when the code is right.
- Every line points to a file and a line. A finding with no place in the code does not go in the
  report.
- An empty section is left out entirely. Do not write "none".
