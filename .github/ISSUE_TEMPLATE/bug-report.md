---
name: Bug report
about: Report a defect in the DROPZONA product (especially money-path / stability bugs)
title: "[Bug] <short summary>"
labels: [bug, needs-triage]
assignees: ''
---

<!--
NEVER paste secrets, tokens, keys, passwords, or an exact file-path+line "treasure map"
for a security-sensitive issue into this public repo. For anything sensitive, file a
placeholder that references the internal security note and take details private.
-->

## Summary
<!-- One sentence: what's broken. -->


## Steps to reproduce
<!-- Numbered, minimal, deterministic if possible. Note concurrency if it's a race (several concurrent triggers, etc.). -->
1. 
2. 
3. 

## Expected result
<!-- What should happen. -->


## Actual result
<!-- What actually happens. Include error text / stack trace class if relevant (redact any secret values). -->


## Severity
<!-- Pick one. Money-loss and crash-on-every-call bugs are P0. -->
- [ ] `P0` — money-loss, data-loss, or crashes a core path (blocks launch)
- [ ] `P1` — breaks a feature or erodes trust
- [ ] `P2` — cosmetic / minor

## Area
<!-- One of: Backend · Frontend · Infra · Security · GTM -->
- [ ] Backend
- [ ] Frontend
- [ ] Infra
- [ ] Security
- [ ] GTM

## Impact / blast radius
<!-- Who/what is affected? Can it lose real funds or overspend a balance? Does it fire near balance depletion or on every call? -->


## Environment
- **Build / prod HEAD:** 
- **Where observed:** <!-- staging · prod · local -->

## Related ticket
<!-- DZ-XX if this maps to an existing build-plan item. -->
