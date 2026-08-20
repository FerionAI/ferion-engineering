# Dependency security (SCA) and updates

Most of the code you ship you did not write. Third-party dependencies are the largest attack surface
in a typical application and the easiest one to manage badly.

## The floor

- **No new high/critical vulnerability** enters through your PR. That is a merge blocker.
- **Existing** vulnerabilities are a backlog with a plan, not an emergency — unless the vulnerable
  path is actually reachable from user input, in which case it is.
- **Pin your versions.** A lockfile committed, and reproducible installs in CI (`npm ci`,
  `pip install -r` with hashes, `go.sum`, …).

## Scanning

| Level | Tool | When |
|---|---|---|
| Manifest scan | your platform's dependency alerts, `npm audit`, `pip-audit`, `govulncheck` | on every PR |
| Full SCA | Trivy, Snyk, Grype, or your platform's SCA | in CI, and on a schedule |
| Container image | Trivy or equivalent | when you build the image |

Two things a scanner will not tell you and you must judge:

- **Reachability.** A critical CVE in a code path your app never calls is lower risk than a medium one
  in your auth middleware. Some tools do reachability analysis; most do not.
- **Transitive blast radius.** The vulnerable package is usually not the one you installed. Check what
  pulls it in before assuming you can just bump it.

## Keeping up to date

- **Automate the boring updates** (Renovate/Dependabot): patch and minor bumps, grouped, with CI
  proving they are safe. `<FILL: which bot, and the grouping policy>`.
- **Major bumps are a task**, with a changelog read and a plan — never an auto-merge.
- **Update regularly, in small steps.** The team that updates monthly does 20-minute upgrades; the
  team that updates yearly does two-week migrations and then postpones again.

## Adding a new dependency (the question before the scan)

The write-less-code ladder applies here first: does the standard library or something already in the
manifest do this? A dependency is a permanent cost — supply chain risk, upgrade work, bundle size,
one more thing to understand at 3am.

If you do add it, check: is it maintained (last release, open issue response)? How many transitive
dependencies does it bring? What is the license? Is the package name the one you meant
(typosquatting is real)?

## Checklist

- [ ] No new high/critical vulnerability introduced.
- [ ] Lockfile updated and committed; CI installs from the lockfile.
- [ ] New dependency justified against the ladder (could it be a few lines instead?).
- [ ] License compatible with the project.
- [ ] Package name verified (no typosquat), source is the official registry.
