# SpeakSense Research MVP Implementation Roadmap

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this roadmap through the linked plans. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Coordinate the nine independently testable implementation plans into one research-ready SpeakSense release without losing the October 2026 competition deadline.

**Architecture:** Foundation/security is the base dependency. Secure provisioning/consent and non-destructive class membership management close onboarding. Acoustic feasibility is an early hard gate and should begin as soon as the web scaffold exists. Audio/offline and model work can overlap after foundation interfaces stabilize; student research flows and authorized history/playback follow scoring; content/PWA/release tasks and teacher/research analytics close the release.

**Tech Stack:** React + TypeScript + Vite, Supabase, IndexedDB/Dexie, Web Audio, Transformers.js/ONNX Runtime Web, Vitest, Playwright.

**Spec:** `docs/superpowers/specs/2026-09-15-speaksense-design.md`

## Global Constraints

- No paid AI APIs.
- Browser-first; phone and laptop support.
- RLS/private audio/research freeze are release blockers, not optional hardening.
- Student account provisioning and research/audio consent must be auditable before formal research data collection.
- Class removal/suspension must not destroy historical attempts/research evidence.
- Students can replay only their own retained recordings through short-lived authorized playback.
- Do not begin the formal Grade 11 research run until the pilot/release gate is satisfied.
- The official submission window is 05/10/2026–10/10/2026.
- A true three-week intervention ending before the final submission date requires the formal intervention to begin by approximately 19/09/2026. If the research-ready release is not validated by then, do not fabricate a three-week dataset; revise the study calendar/protocol transparently.

---

## Ordered plans

1. `2026-09-15-01-foundation-auth-data.md` — secure standalone app, roles, class joining, research freeze.
2. `2026-09-15-01b-account-provisioning-consent.md` — student self-registration, Admin teacher provisioning, research/audio consent.
3. `2026-09-15-01c-class-membership-management.md` — teacher suspend/restore/remove membership without destructive history deletion.
4. `2026-09-15-02-audio-offline-storage.md` — recording, preprocessing, private storage, offline queue.
5. `2026-09-15-03-acoustic-alignment-scoring.md` — early model benchmark hard gate, alignment, six scores, confidence/error model.
6. `2026-09-15-04-student-practice-adaptive-test.md` — three Labs, feedback, adaptive practice, pre/post and cohort enforcement.
7. `2026-09-15-04b-attempt-history-playback.md` — student attempt history and short-lived authorized playback.
8. `2026-09-15-06-content-pwa-health-release.md` — controlled content bank, US/UK publication, PWA/offline readiness, health/release metadata.
9. `2026-09-15-05-teacher-validation-research-admin.md` — analytics, blind validation, exports, retention/admin, full pilot gate.

## Dependency and parallelization rules

- [ ] Complete Plan 01 Tasks 1–4 before any feature depends on Supabase tables/RLS.
- [ ] Complete Plans 01b and 01c before real student onboarding/class administration; test accounts may be seeded locally before then.
- [ ] Start Plan 03 Task 1 (model benchmark) immediately after the Vite scaffold exists; this is the highest technical-risk gate and may run in parallel with remaining Plan 01/01b/01c work.
- [ ] Plan 02 may start once `attempts` schema and auth identity contracts are stable; its research-audio retention path must consume Plan 01b consent state.
- [ ] Do not implement fake UI scoring while waiting for model feasibility. If Plan 03 Task 1 fails, stop scoring-dependent product work and revise the architecture.
- [ ] Plan 03 Tasks 2–9 depend on a passing model candidate and Plan 02's `PreparedAudio` contract.
- [ ] Plan 06 Tasks 1–2 (Content Bank/publishing) should be available before final research test/practice content is frozen; PWA/health/release tasks may continue in parallel afterward.
- [ ] Plan 04 depends on stable `ScoreResult`, `SyncQueue`, class/study/cohort records, and published versioned content/reference contracts.
- [ ] Plan 04b depends on Plan 02 private playback and Plan 04 persisted attempts.
- [ ] Plan 05 analytics can begin with fixture data after schemas are stable, but its Task 12 pilot gate depends on Plans 01, 01b, 01c, 02, 03, 04, 04b, and Plan 06 release-critical tasks being complete.

## Research-start gate

Before any formal pre-test is counted as competition research data, verify all of the following in one release candidate:

- [ ] production/staging Auth + RLS security tests pass;
- [ ] student self-registration with a valid active class code works end-to-end;
- [ ] teacher membership suspend/restore/remove behavior is authorization-safe and non-destructive;
- [ ] current versioned research consent is recorded and audio-retention consent is enforced;
- [ ] student class join works end-to-end;
- [ ] selected acoustic model has documented iPhone/Android/laptop benchmark results;
- [ ] US/UK references used by the pre-test are versioned and published;
- [ ] scoring/adaptive/test/reference versions are frozen in a Research Snapshot;
- [ ] Word/Sentence/Passage attempts can record, score, persist, and sync;
- [ ] students can view their own attempt history and only their own retained audio;
- [ ] low-quality/low-confidence states behave as specified;
- [ ] control cohort cannot access adaptive intervention through UI or direct database calls;
- [ ] retained audio is private and authorized signed playback works;
- [ ] pre-test mode hides detailed feedback and disallows immediate retry;
- [ ] at least one teacher can complete a blind human review without seeing AI score first;
- [ ] de-identified CSV export contains no name/username/email/auth UUID/audio path;
- [ ] offline pending-sync survives reload/reconnect;
- [ ] PWA/app shell and assigned non-sensitive content survive the documented offline test;
- [ ] a small pilot dry run is completed and documented.

## Engineering release sequence

Use tags/releases rather than silently changing research logic:

- `v0.1-foundation` after Plans 01 + 01b + 01c.
- `v0.2-audio` after Plan 02.
- `v0.3-scoring-pilot` after Plan 03; still not a formal research release until scoring version/reference/test set are frozen.
- `v0.4-student-research` after Plans 04 + 04b and Plan 06 content publication tasks.
- `v0.5-release-candidate` after Plan 06 PWA/health/release checks.
- `v1.0-research-ready` only after Plan 05 Task 12 pilot gate.

## Deadline decision rule

The three-week experimental design is more important than pretending the original calendar was met. Therefore:

- If `v1.0-research-ready` is validated early enough to complete three full intervention weeks plus post-test before final submission, begin the formal study.
- If it is validated too late, run a pilot/feasibility dataset, document the actual duration, and revise the formal study timing rather than labeling fewer days as “three weeks”.
- Do not alter scoring/reference/adaptive versions after pre-test to improve results; improvements create a new future version.

## Program exit criteria

SpeakSense reaches `v1.0-research-ready` only when the full definition of done in the approved specification and Plan 05 pilot gate are satisfied. Visual polish, extra gamification, free speaking, chatbot, parent features, native apps, and paid AI integrations remain out of scope until after the research-critical release.