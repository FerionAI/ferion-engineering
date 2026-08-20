---
name: privacy
description: Privacy and personal data protection (GDPR / LGPD / CCPA) — how to handle personal data in code safely and compliantly. Use when a change involves personal data, when asking "is this PII?", "can this leak user data?", "do we need consent?", "how long do I keep this?", "how do I mask this in logs or session recordings?", when designing signup/profile/payment flows, or when integrating tools that receive user data. Complements `quality` (security) with the privacy layer.
---

# Privacy and personal data

You make sure personal data is handled safely and compliantly. Privacy is **by design**: decided in
the `plan`, not patched afterwards. This complements the security in `quality` (OWASP) with the
legal/ethical layer. It is not legal advice — for sensitive cases, involve your data protection
contact: `<FILL: DPO / privacy owner>`.

> **Which regime applies:** `<FILL: GDPR / LGPD / CCPA / none>`. The engineering rules below are
> nearly identical across them — the differences are in the legal bases, the notification deadlines
> and the data subject rights, which are your privacy contact's call, not the agent's.

## Privacy principles that become engineering rules

- **Minimization/necessity:** collect and keep only the data the purpose needs. Less PII = less risk
  (the same instinct as writing less code: the best data is the data you do not store).
- **Purpose and legal basis:** every processing activity has a clear purpose and a legal basis
  (consent, contract, legal obligation, legitimate interest…). Do not reuse data for another purpose
  without a basis.
- **Transparency:** the data subject knows what is collected and why.
- **Security:** encryption in transit and at rest, least-privilege access (ties into OWASP A01/A04 in
  `quality`).
- **Data subject rights:** access, correction, deletion, portability and consent withdrawal must be
  technically possible.

## Where engineering usually slips (always check)

1. **PII in logs/telemetry** — never log identification numbers, emails, phone numbers or payment
   data. Mask or use a field allowlist in the observability pipeline and the application logs
   (OWASP A09).
2. **Session recording** — mask sensitive fields in recordings and heatmaps; do not capture screens
   with PII visible. Configure the tool's masking, do not rely on the default.
3. **Product analytics** — never send PII as an event parameter; respect consent before firing;
   anonymize where applicable.
4. **Data in external tools** — third parties receive only the attributes they need; a data
   processing agreement with the vendor (`<FILL: check the DPAs of your vendors>`).
5. **Retention** — every piece of personal data has a retention period and a purge/anonymization
   routine. No "keep it forever just in case".
6. **Children's data** (if applicable) — special treatment and guardian consent.
   `<FILL: does this product process data of minors?>`.
7. **Deletion/portability** — delete for real (including backups and derived datasets) and export in
   a readable format when the data subject asks.

## In the flow

- **`plan` (spec-flow):** build the feature's mini data map — which personal data, purpose, legal
  basis, retention, where it goes. See `references/data-map-and-checklist.md`.
- **Implementation:** minimization, masking, encryption, access control.
- **`review`:** run the privacy checklist alongside the security one.
- **Incident:** a personal data leak is an incident (`incident`) **and** a privacy event — notify the
  privacy contact; the decision to notify the regulator and the data subjects belongs to them and
  legal. Run the response and the postmortem through `incident`.

## Output

A feature that handles personal data with: a data map in the plan, minimization, masking in
logs/analytics/recordings, a defined retention period, and the data subject rights technically
satisfied.
