# SpeakSense Teacher Analytics, Human Validation, Research, and Admin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the competition research workflow with teacher analytics, class heatmaps, blind human validation, de-identified exports, control-vs-experimental research analysis, admin version/retention controls, and a pilot dry-run gate.

**Architecture:** Read analytics from RLS-protected Supabase views/RPCs rather than loading unrestricted raw datasets into the browser. Human reviews are write-once/blinded until submission. Research calculations use frozen versions and anonymous participant codes. Admin actions that freeze configuration or delete retained audio are audited.

**Tech Stack:** React, TypeScript, Supabase/PostgreSQL, CSV generation in browser/server RPC as appropriate, Vitest, Playwright, SQL integration tests.

**Spec:** `docs/superpowers/specs/2026-09-15-speaksense-design.md`

## Global Constraints

- Teachers see only classes/studies they are authorized to manage.
- Human reviewers must not see automated scores before submitting their rating.
- Planned validation subset is approximately 20–30% of research recordings.
- Exports use anonymous participant codes such as `S001`, not names, by default.
- Required research views include pre/post means, gains, six components, weekly progress, target-error change, practice minutes/attempts, completion, AI-human agreement, confidence distribution.
- Frozen scoring/test/reference/adaptive versions are immutable.
- Audio deletion must be supported and logged; metadata may remain when policy permits.

---

## File map

- `src/teacher/analyticsService.ts` — class/student aggregated analytics.
- `src/pages/teacher/TeacherDashboard.tsx`
- `src/pages/teacher/ClassAnalyticsPage.tsx`
- `src/pages/teacher/HumanValidationPage.tsx`
- `src/research/validationService.ts` — blind-review queue and agreement metrics.
- `src/research/statistics.ts` — deterministic descriptive/comparison calculations.
- `src/research/exportService.ts` — de-identified CSV export.
- `src/pages/teacher/ResearchDashboardPage.tsx`
- `src/admin/versionService.ts` — scoring/adaptive/reference/test version management.
- `src/admin/retentionService.ts` — audio retention/deletion controls.
- `src/pages/admin/AdminDashboard.tsx`
- `supabase/migrations/007_analytics_views.sql`
- `supabase/migrations/008_human_review.sql`
- `supabase/migrations/009_retention_audit.sql`
- `tests/unit/research/*`, `tests/sql/007_*`, `tests/e2e/teacher-research.spec.ts`.

### Task 1: Add safe aggregated analytics queries

**Files:**
- Create: `supabase/migrations/007_analytics_views.sql`
- Create: `src/teacher/analyticsService.ts`
- Create: `tests/sql/007_analytics_views.sql`
- Create: `tests/unit/research/analyticsService.test.ts`

**Interfaces:**
- Produces RPCs/views for authorized teacher scope:
  - `class_overview(p_class_id uuid)`
  - `class_error_heatmap(p_class_id uuid)`
  - `student_pronunciation_history(p_student_id uuid, p_class_id uuid)`

- [ ] **Step 1: Write SQL authorization and aggregation tests**

Verify teacher-owner can query; unrelated teacher fails/gets no rows; output includes completion, average score, error-family counts, and student anonymous/display context appropriate to teacher role.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement SECURITY INVOKER views/RPCs that still honor RLS or explicitly validate teacher ownership**

Do not use unrestricted `security definer` helpers without explicit authorization checks.

- [ ] **Step 4: Run SQL/unit tests**
- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/007_analytics_views.sql src/teacher tests
git commit -m "feat: add teacher pronunciation analytics"
```

### Task 2: Build teacher class analytics and heatmap UI

**Files:**
- Create: `src/pages/teacher/ClassAnalyticsPage.tsx`
- Create: `src/components/analytics/ClassHeatmap.tsx`
- Modify: `src/pages/teacher/TeacherDashboard.tsx`
- Create: `tests/unit/research/ClassHeatmap.test.tsx`

**Interfaces:**
- Consumes analytics service.
- Produces overview cards, trend summaries, common-error table/heatmap, and student drill-down links.

- [ ] **Step 1: Write UI tests for empty, partial, and populated class datasets**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement accessible table-first heatmap**

Color is optional decoration; each cell must also expose text/icon/status and numeric evidence so the result is understandable without color.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 3: Implement blind human-review database workflow

**Files:**
- Create: `supabase/migrations/008_human_review.sql`
- Create: `src/research/validationService.ts`
- Create: `tests/sql/008_human_review.sql`

**Interfaces:**
- Produces:
  - `claim_review_item(p_study_id uuid)`
  - `submit_human_review(p_attempt_id uuid, p_scores jsonb, p_notes text)`
  - `reveal_review_comparison(p_attempt_id uuid)` only after reviewer submission.

- [ ] **Step 1: Write SQL tests for blinding**

Before submission, reviewer response must exclude automated overall/component score fields. After valid submission, the comparison RPC may expose the frozen automated snapshot. A reviewer cannot overwrite a submitted review.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement review queue selection**

Queue should support a reproducible study-specific target fraction in the 20–30% range. Store the selected sample manifest/version so the subset can be reported in the research log.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 4: Build the Human Validation UI

**Files:**
- Create: `src/pages/teacher/HumanValidationPage.tsx`
- Create: `src/components/research/HumanRatingForm.tsx`
- Create: `tests/e2e/human-validation.spec.ts`

**Interfaces:**
- Consumes `validationService` and signed authorized audio playback.
- Produces blind review form for overall + six components, optional notes, then comparison after submit.

- [ ] **Step 1: Write E2E test proving automated score is absent before submit**
- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement review UI with participant code/item ID/audio only before rating**
- [ ] **Step 4: Submit rating and verify comparison appears afterward**
- [ ] **Step 5: Commit**

### Task 5: Implement research statistics helpers

**Files:**
- Create: `src/research/statistics.ts`
- Create: `tests/unit/research/statistics.test.ts`

**Interfaces:**
- Produces pure functions:

```ts
export function mean(values: number[]): number | null;
export function meanGain(pre: number[], post: number[]): number | null;
export function pearsonCorrelation(xs: number[], ys: number[]): number | null;
export function meanAbsoluteError(xs: number[], ys: number[]): number | null;
export function proportionWithin(xs: number[], ys: number[], tolerance: number): number | null;
```

- [ ] **Step 1: Write numeric fixture tests including empty/constant arrays**

Correlation must return `null` when undefined (e.g. zero variance), not NaN disguised as a valid result.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement numerically stable deterministic helpers**
- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 6: Add research dataset RPC and dashboard service

**Files:**
- Modify: `supabase/migrations/007_analytics_views.sql`
- Create: `src/research/researchDashboardService.ts`
- Create: `tests/sql/007_research_dataset.sql`
- Create: `tests/unit/research/researchDashboardService.test.ts`

**Interfaces:**
- Produces de-identified rows keyed by `participant_code`, cohort, phase, six components, overall, confidence, practice minutes, attempts, error-family counts, and frozen version IDs.

- [ ] **Step 1: Write SQL tests for de-identification and study scoping**

No participant real name, username, synthetic email, raw storage path, or auth UUID should appear in the default research dataset payload.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement study-scoped authorized RPC/view**
- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 7: Build the Research Dashboard

**Files:**
- Create: `src/pages/teacher/ResearchDashboardPage.tsx`
- Create: `src/components/research/ResearchSummary.tsx`
- Create: `tests/unit/research/ResearchSummary.test.tsx`

**Interfaces:**
- Consumes research dashboard dataset/statistics.
- Produces required views from the spec.

- [ ] **Step 1: Write component tests with a fixed two-cohort fixture**

Require display of pre mean, post mean, gain, six component gains, weekly progress, error-family change, practice volume, completion, MAE/correlation/±5 proportion, and confidence distribution.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement dashboard with transparent sample counts beside metrics**

Never display a metric without its `n` where missing/excluded samples could affect interpretation.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 8: Implement de-identified CSV export

**Files:**
- Create: `src/research/exportService.ts`
- Create: `tests/unit/research/exportService.test.ts`

**Interfaces:**
- Produces `buildResearchCsv(rows: ResearchDatasetRow[]): string`.

- [ ] **Step 1: Write export tests**

Assert headers include participant code/cohort/phase/scores/confidence/version IDs and exclude display name, username, email, UUID, audio path.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement RFC4180-compatible CSV escaping**
- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 9: Implement admin version management

**Files:**
- Create: `src/admin/versionService.ts`
- Create: `src/pages/admin/VersionManagementPage.tsx`
- Create: `tests/unit/research/versionService.test.ts`
- Create: `tests/sql/009_version_immutability.sql`

**Interfaces:**
- Produces create/publish/freeze flows for scoring/adaptive/test/reference version metadata.

- [ ] **Step 1: Write tests proving frozen/in-use versions cannot be edited/deleted**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement immutable version transitions and UI**

Editing means creating a new version. Never mutate a version referenced by a frozen study.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 10: Implement audio-retention deletion and audit trail

**Files:**
- Create: `supabase/migrations/009_retention_audit.sql`
- Create: `src/admin/retentionService.ts`
- Create: `src/pages/admin/RetentionPage.tsx`
- Create: `tests/sql/009_retention_audit.sql`

**Interfaces:**
- Produces admin operations to delete one participant's retained audio or all audio for a study while preserving permitted structured results and recording an audit event.

- [ ] **Step 1: Write tests for unauthorized deletion, authorized scoped deletion, and metadata preservation**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement deletion workflow with explicit confirmation and immutable audit event**

Audit must store actor, scope, timestamp, reason/action type, count of objects targeted/deleted, and study/participant reference where applicable.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 11: Add research integrity checks and exclusion log

**Files:**
- Create: `src/research/integrityService.ts`
- Create: `src/pages/teacher/ResearchIntegrityPage.tsx`
- Create: `tests/unit/research/integrityService.test.ts`

**Interfaces:**
- Produces checks for scoring-version consistency, content/reference versions, missing data, low-confidence samples, human-validation completion, and excluded attempts/reasons.

- [ ] **Step 1: Write tests for mixed-version and missing-data detection**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement integrity report with blocking vs warning severity**

A frozen-study version mismatch is blocking. Low confidence is a warning/review condition unless the research protocol explicitly excludes it.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 12: Execute one end-to-end pilot dry run and release gate

**Files:**
- Create: `tests/e2e/teacher-research.spec.ts`
- Create: `docs/research/pilot-dry-run.md`
- Create: `docs/research/scoring-limitations.md`

**Interfaces:**
- Validates the complete research-ready workflow; produces documented evidence for the project/research log.

- [ ] **Step 1: Write E2E scenario**

Teacher creates class; students join; admin creates study; participants assigned control/experimental + accent; versions freeze; both cohorts pre-test; experimental gets practice while control is blocked; post-test recorded; reviewer completes blinded subset; teacher sees analytics; CSV is de-identified; retention test deletes pilot audio.

- [ ] **Step 2: Run full automated suite**

Run: `npm test && npm run build && npm run test:e2e`
Expected: PASS.

- [ ] **Step 3: Run device pilot on representative iPhone Safari, Android Chrome, desktop Chrome/Edge, and macOS Safari where feasible**

Record browser/device, microphone compatibility, cold/cached model load, inference latency, sync behavior, and any excluded attempts in `docs/research/pilot-dry-run.md`.

- [ ] **Step 4: Write scoring limitations**

`docs/research/scoring-limitations.md` must explicitly state controlled-reading scope, model uncertainty, device/microphone effects, confidence behavior, and that SpeakSense is learning support rather than a diagnostic or 100%-accurate judge.

- [ ] **Step 5: Commit release-gate evidence**

```bash
git add tests/e2e/teacher-research.spec.ts docs/research
git commit -m "test: complete SpeakSense research pilot gate"
```

## Teacher/research exit criteria

Teachers can securely analyze their classes, blind reviewers can rate the planned subset without seeing AI scores first, the research dashboard compares control and experimental groups with transparent sample counts, exports are de-identified, admin version and retention controls are auditable, and at least one full pilot dry run satisfies the design specification's definition of done.