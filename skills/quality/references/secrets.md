# Secret management

A leaked secret is not a bug you fix by deleting the commit — the history is public the moment it is
pushed. Prevention is the whole game.

## The rules

1. **Never in the code.** No token, key, password or connection string in a source file, a config
   file that is committed, a test fixture, or a comment.
2. **Environment or a secret manager.** Local: `.env` (git-ignored, with a committed `.env.example`
   holding only the key names). Deployed: your platform's secret manager, injected at runtime.
3. **Never in logs.** Mask on the way out; assume every log line will be read by someone who should
   not see the value (`privacy`).
4. **Never in the URL.** Query strings end up in access logs, proxies, browser history and referrers.
   Use a header.
5. **Least privilege and short-lived.** A token scoped to one action beats an admin token. Prefer
   OIDC/workload identity over a long-lived key in CI.
6. **Rotate on a schedule and on suspicion.** A secret with no rotation plan is a permanent liability.

## Secret scanning (the safety net)

- **Pre-commit:** a scanner (`gitleaks`, `detect-secrets`, `talisman`) in a git hook. This is where
  you want to catch it — before the push.
- **CI:** the same scan on the PR, so a hook someone skipped does not get through.
- **Platform:** enable your host's push protection and secret scanning alerts.

## It leaked. Now what?

Deleting the commit does not help — assume it is compromised.

1. **Rotate the secret first.** Right now, before the cleanup. Revoke the old value.
2. **Assess the blast radius:** what did that credential have access to? Check the audit logs for use
   you did not make.
3. **Clean the history** (`git filter-repo`, or the platform's tooling) — this rewrites history and
   requires coordination with everyone who has a clone. Do it after rotation, not instead of it.
4. **Record it as an incident** (`incident`) if the secret gave access to personal data or production
   — including the privacy path.
5. **Fix the hole in the process:** the scanner that was not installed, the `.env` that was not
   ignored, the example file that had a real value in it.

## Review checklist

- [ ] No hardcoded value that looks like a credential (grep for `key`, `token`, `secret`, `password`,
      `_KEY`, long base64/hex strings).
- [ ] `.env` and equivalents are git-ignored; `.env.example` has names, never values.
- [ ] New secrets registered in the secret manager, not pasted into a chat or a ticket.
- [ ] CI uses scoped credentials, ideally short-lived (OIDC), not a long-lived personal token.
- [ ] Logging masks the sensitive fields.
