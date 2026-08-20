# Security — OWASP

The objective floor for anything touching authentication, authorization, personal data, external
input or dependencies. Walk it whenever the diff touches one of those.

## OWASP Top 10 — what to check in the code

| Risk | What to verify in the change |
|---|---|
| **Broken access control** | Authorization checked **per object**, not just per route. An id in the URL is not proof of ownership. Listings filter by access rights **in the query**, never in the front end. |
| **Cryptographic failures** | TLS everywhere; secrets and personal data encrypted at rest; no home-made crypto; passwords hashed with a modern KDF (argon2/bcrypt). |
| **Injection** | Parameterized queries / prepared statements — never string concatenation. This includes SQL, NoSQL, OS commands, LDAP and template engines. |
| **Insecure design** | The flow itself is safe: rate limiting, idempotency on state changes, no security decision on the client. Threat model the sensitive flows (`threat-modeling.md`). |
| **Security misconfiguration** | No debug in production, no default credentials, restrictive CORS, security headers, verbose errors off. |
| **Vulnerable components** | Dependencies scanned and pinned (`dependency-security.md`). |
| **Identification/auth failures** | Session expiry and rotation, brute-force protection, MFA where it matters, no token in a URL. |
| **Software/data integrity** | Verified dependencies, signed artifacts, no deserialization of untrusted data. |
| **Logging/monitoring failures** | Security events logged (auth, permission change, failure), **no PII in the log** (`privacy`), alerting that someone actually reads. |
| **SSRF** | Any URL that comes from a user is validated against an allowlist; no fetching arbitrary internal addresses. |

## API Security Top 10 — the API-specific additions

- **BOLA (object level):** the most common and most expensive API bug. `GET /orders/123` must check
  that order 123 belongs to the caller. Test it with another user's id.
- **BFLA (function level):** an admin endpoint reachable by a regular user because the check is only
  in the UI.
- **Unrestricted resource consumption:** pagination limits, payload size limits, timeouts, rate limits.
- **Mass assignment:** never bind a request body straight onto a model. Allowlist the fields.
- **Improper inventory:** old API versions still deployed and unpatched; undocumented endpoints.

## The review checklist

- [ ] Every external input validated at the boundary (type, range, format, size) — allowlist, not blocklist.
- [ ] Authorization checked at object and function level, server-side, fail-closed.
- [ ] Parameterized queries; no dynamic SQL built from input.
- [ ] No secret, token or credential in the code, in the logs or in the tests (`secrets.md`).
- [ ] Errors do not leak internals (stack trace, SQL, internal paths) to the client.
- [ ] New dependencies scanned; no new high/critical vulnerability.
- [ ] Security events logged without PII; sensitive fields masked.
- [ ] Rate limiting / abuse protection where the endpoint is public or expensive.

## Principles

- **Fail closed.** When in doubt, deny. An authorization bug that fails open is a breach; one that
  fails closed is a bug report.
- **Validate at the boundary, trust inside.** One validated entry point beats defensive checks
  scattered everywhere.
- **The client is never a security control.** A hidden button is not authorization.
- **Never cut this for speed** — security is one of the guardrails that efficiency does not touch (P8).
