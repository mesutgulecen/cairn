# Prompt: application security audit (delta run)

| Argument | Default | Meaning |
|---|---|---|
| `scope` | whole app | surface to review |
| `previous` | last run | the run to diff against |
| `mode` | `read-only` | `read-only` \| `exploit` (explicit written authorisation, own systems only) |
| `output` | `docs/audits/<date>/app-security-<date>.md` | report path |

A delta run: read the previous report first and check whether each finding is
still live before hunting new ones. A security report that re-finds what was
already fixed trains its readers to skim.

## 1. Map the surface before judging it

List every entry point with what it trusts: HTTP routes and their auth
requirement, webhooks and how each is verified, scheduled jobs, message
consumers, admin paths, file uploads, service-to-service calls. **An endpoint
missing from this list cannot be reviewed**, and the ones that go missing are the
ones added since the last review.

For each, record: who may call it, what proves it, and what happens when the
proof is absent rather than wrong. Those are different failures and they often
have different code paths.

## 2. Authentication and authorisation

- Is authorisation checked at the **resource**, or only at the route? A route
  guard that says "logged in" and a handler that reads an id from the request is
  an object-reference vulnerability with extra steps.
- Does every multi-tenant query carry its scope, or does application code apply
  it by convention? A convention holds until one query is written by someone in a
  hurry. Prefer a boundary the database enforces.
- What happens on an **absent** token versus a malformed one versus an expired
  one? Fail-closed on all three, and confirm it rather than assuming it.
- Are tokens invalidated on logout, password change and role change? A revoked
  role that lives until token expiry is a real window, and it is usually hours.

## 3. Input, output and injection

Parameterised queries everywhere; check the exceptions rather than the rule. Then
the three that survive modern frameworks: template injection in server-rendered
strings, command injection through anything shelling out, and deserialisation of
attacker-controlled data. Check that user-controlled content cannot reach a
markup context unescaped, including error messages, which are the classic
forgotten sink.

## 4. Secrets

Grep history, not only the working tree: a rotated secret that was ever committed
is still exposed. Confirm secrets come from the environment or a manager and are
absent from logs, error payloads and crash reports. Check what your logger does
with a struct that contains a token field. Redaction that depends on the caller
remembering is not redaction.

## 5. Dependencies

Run the audit tool, then read the exclusions file. **An exclusion written for one
dependency can silence the whole check**: a suppression written broadly once
hid every subsequent advisory in that class. And a narrow version override,
added to force a fix, **pins the vulnerable version in place** once upstream
moves past it: the override that fixed the problem becomes the reason it
persists. Diff overrides against upstream at every run.

## 6. Rate limits, resource limits, and the failure mode

Every unauthenticated endpoint needs a limit, and every limit needs a decision
about what happens when the limiter itself is unavailable. Fail-open is a
choice, and it should be a written one.

## Output

Findings ranked by exploitability × impact, each with a reproduction or a
`file:line`. Unverified suspicions stay in the report labelled as such. No
exploitation without explicit written authorisation, and never against a system
you do not own.
