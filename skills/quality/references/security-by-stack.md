# Security per stack

`security-owasp.md` is the concept. This is what it looks like in each language — the specific traps,
and the tool that finds them for you.

## TypeScript / Node

- **Injection:** use the query builder or parameterized queries — never template-literal SQL. In an
  ORM, a `raw()` call is the thing to grep for in review.
- **Prototype pollution:** merging untrusted objects (`Object.assign`, deep-merge utilities) can set
  `__proto__`. Validate with a schema (zod/valibot) before merging anything from a request.
- **Mass assignment:** never pass `req.body` straight into `create()`/`update()`. Parse into a typed,
  allowlisted shape.
- **`eval`, `new Function`, `child_process.exec` with interpolation:** all remote code execution
  waiting to happen. `execFile` with an argument array instead of `exec` with a string.
- **Regex DoS:** a user-supplied string against a catastrophic-backtracking regex hangs the event loop.
- Tools: `eslint-plugin-security`, `npm audit`, semgrep.

## Python

- **Injection:** parameterized cursors (`cursor.execute(sql, params)`), never f-strings in SQL.
- **Deserialization:** `pickle.loads` on untrusted data is remote code execution. `yaml.safe_load`,
  never `yaml.load`.
- **`subprocess` with `shell=True`** and interpolated input — same class as `exec`.
- **Path traversal:** validate and normalize any path built from input before opening it.
- **Django/Flask specifics:** `DEBUG=False` in production (a debug page leaks everything), `SECRET_KEY`
  from the environment, CSRF enabled, `ALLOWED_HOSTS` set.
- Tools: `bandit`, `pip-audit`, semgrep.

## Go

- **SQL:** `db.Query(q, args...)`, never `fmt.Sprintf` into the query.
- **Ignored errors:** `_ = doSomething()` on a security-relevant call is how a failed check becomes a
  pass. `errcheck` catches it.
- **`os/exec`:** pass arguments as a slice; do not build a shell string.
- **Integer overflow on conversions** (`int64` → `int32`) in size/limit checks.
- **Goroutine leaks and unbounded concurrency** on a public endpoint = DoS.
- Tools: `gosec`, `govulncheck`, `staticcheck`.

## Java / .NET

- **Deserialization** of untrusted data (the classic Java RCE class). Prefer JSON with a strict schema
  over native serialization.
- **XXE:** disable external entities in every XML parser — the default is often unsafe.
- **SQL:** `PreparedStatement` / parameterized commands, always.
- **Spring:** method-level authorization (`@PreAuthorize`) — an endpoint protected only by a URL rule
  is fragile to refactoring. Actuator endpoints locked down.
- Tools: `spotbugs` + `find-sec-bugs`, OWASP Dependency-Check, the platform analyzers.

## Everywhere

| Trap | Fix |
|---|---|
| Validating in the front end only | validate server-side; the client is not a control |
| Authorization by URL pattern | authorize per object, in the handler |
| Secrets in config committed to the repo | `secrets.md` |
| Verbose errors returned to the client | generic message out, detail in the log (without PII) |
| Timing-unsafe comparison of tokens | use the constant-time compare your stdlib provides |
