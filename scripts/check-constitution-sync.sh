#!/usr/bin/env sh
# Fails if the constitution copy drifted from the source. Wire into CI or a pre-commit hook.
# ponytail: plain diff; turn it into a loop the day there is more than one copy.
diff -q memory/constitution.md skills/constitution/references/constitution.md >/dev/null && exit 0
echo "ERROR: skills/constitution/references/constitution.md drifted from memory/constitution.md — sync the two."
exit 1
