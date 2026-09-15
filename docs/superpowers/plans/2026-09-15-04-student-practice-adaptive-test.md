# SpeakSense Student Practice, Adaptive Learning, and Test Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the recording/scoring primitives into the complete student experience: Word/Sentence/Passage Labs, bilingual feedback, progress/error maps, deterministic adaptive practice, and research-safe pre-test/post-test behavior with control-group intervention blocking.

**Architecture:** Student pages consume pure domain services from the audio/scoring plans and persist attempts through the sync queue. Adaptive selection is deterministic and versioned. Test mode uses the frozen research snapshot to restrict feedback/retries and enforce cohort/accent/version rules.

**Tech Stack:** React, TypeScript, React Router, Supabase, existing AudioEngine/ScoringEngine/SyncQueue, Vitest, Testing Library, Playwright.

**Spec:** `docs/superpowers/specs/2026-09-15-speaksense-design.md`

## Global Constraints

- Learning modes are Word Lab, Sentence Lab, Passage Lab only for competition MVP.
- Feedback is bilingual English–Vietnamese.
- Student research accent is locked for the study.
- Control participants can do pre/post collection but cannot access adaptive intervention during the study.
- Test mode hides detailed correction until completion and forbids immediate same-item repetition.
- Adaptive practice is deterministic; no generative AI.
- Student UI must expose explicit sync/confidence states and never imply 100% scoring accuracy.

---

## File map

- `src/practice/practiceService.ts` — content loading and attempt orchestration.
- `src/practice/sessionMachine.ts` — stable student practice state machine.
- `src/adaptive/AdaptiveEngine.ts` — need scoring and deterministic content allocation.
- `src/adaptive/adaptiveVersions.ts` — pilot/version configuration.
- `src/student/progressService.ts` — history, trends, error map.
- `src/research/testMode.ts` — pre/post restrictions from research snapshot.
- `src/pages/student/PracticeHomePage.tsx`
- `src/pages/student/WordLabPage.tsx`
- `src/pages/student/SentenceLabPage.tsx`
- `src/pages/student/PassageLabPage.tsx`
- `src/pages/student/ProgressPage.tsx`
- `src/pages/student/ResearchStatusPage.tsx`
- `src/components/scoring/ScoreSummary.tsx`
- `src/components/scoring/ErrorFeedback.tsx`
- `tests/unit/practice/*`, `tests/e2e/student-practice.spec.ts`, `tests/e2e/research-test-mode.spec.ts`.

### Task 1: Build the practice-session state machine

**Files:**
- Create: `src/practice/sessionMachine.ts`
- Create: `tests/unit/practice/sessionMachine.test.ts`

**Interfaces:**
- Produces states: `loading -> ready -> recording -> analyzing -> result -> queued|synced` plus `retryQuality`, `modelError`, `syncError`.

- [ ] **Step 1: Write transition tests**

Cover valid practice attempt, low-quality retry, model failure, successful local score while offline, and cancel.

- [ ] **Step 2: Run `npm test -- sessionMachine.test.ts` and verify failure**
- [ ] **Step 3: Implement a pure reducer/state machine with explicit events**
- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

```bash
git add src/practice/sessionMachine.ts tests/unit/practice/sessionMachine.test.ts
git commit -m "feat: add student practice session state"
```

### Task 2: Implement practice orchestration service

**Files:**
- Create: `src/practice/practiceService.ts`
- Create: `tests/unit/practice/practiceService.test.ts`

**Interfaces:**
- Produces:

```ts
export type PracticeMode = 'word'|'sentence'|'passage';
export async function submitPracticeAttempt(input: {
  studentId: string;
  contentId: string;
  mode: PracticeMode;
  accent: 'us'|'uk';
  preparedAudio: PreparedAudio;
  audioBlob: Blob;
  studyContext?: { studyId: string; phase: 'pre'|'intervention'|'post' };
}): Promise<{ localAttemptId: string; result: ScoreResult; syncState: 'pending'|'synced' }>;
```

- [ ] **Step 1: Write orchestration tests with fake scorer and queue**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement reference lookup -> score -> persist local payload -> enqueue**

Persist scoring/reference/model IDs and device/browser metadata with every research attempt.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 3: Build reusable score and bilingual error UI

**Files:**
- Create: `src/components/scoring/ScoreSummary.tsx`
- Create: `src/components/scoring/ErrorFeedback.tsx`
- Create: `tests/unit/practice/ScoreSummary.test.tsx`

**Interfaces:**
- Consumes `ScoreResult`.
- Produces accessible overall + six component display and confidence warning.

- [ ] **Step 1: Write UI tests**

Require all six labels, overall score, confidence text, and bilingual correction copy for a supplied final-sound error.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement components without color-only semantics**

Low confidence must visibly show a message such as: `Kết quả này có độ tin cậy thấp; giáo viên có thể cần kiểm tra lại.`

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 4: Implement Word, Sentence, and Passage Labs

**Files:**
- Create: `src/pages/student/PracticeHomePage.tsx`
- Create: `src/pages/student/WordLabPage.tsx`
- Create: `src/pages/student/SentenceLabPage.tsx`
- Create: `src/pages/student/PassageLabPage.tsx`
- Modify: `src/app/routes.tsx`
- Create: `tests/e2e/student-practice.spec.ts`

**Interfaces:**
- Consumes `PracticeMode`, `RecorderPanel`, `submitPracticeAttempt`, score components.
- Produces routes `/student/practice/word`, `/sentence`, `/passage`.

- [ ] **Step 1: Write E2E flow with deterministic mocked acoustic output**

For each mode: open item -> record fixture -> analyze -> render six scores -> show feedback -> allow retry in normal practice -> queue/sync.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement three focused pages sharing a common practice shell**

Passage items must enforce the MVP content length contract (40–80 words) at content validation time, not by truncating at render time.

- [ ] **Step 4: Run E2E and unit suite**
- [ ] **Step 5: Commit**

### Task 5: Implement progress and pronunciation error map

**Files:**
- Create: `src/student/progressService.ts`
- Create: `src/pages/student/ProgressPage.tsx`
- Create: `tests/unit/practice/progressService.test.ts`

**Interfaces:**
- Produces:

```ts
export type ErrorMapRow = { family: string; attempts: number; errorCount: number; weightedSeverity: number; trend: 'improving'|'stable'|'worsening'|'insufficient' };
export async function getStudentProgress(studentId: string): Promise<{ recentScores: ScoreResultSummary[]; errorMap: ErrorMapRow[] }>;
```

- [ ] **Step 1: Write aggregation tests**

Use fixtures across dates; verify no cross-student data; verify trend needs a minimum evidence count before claiming improvement.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement service and UI sections: My Progress, My Common Errors**
- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 6: Implement deterministic AdaptiveEngine

**Files:**
- Create: `src/adaptive/AdaptiveEngine.ts`
- Create: `src/adaptive/adaptiveVersions.ts`
- Create: `tests/unit/practice/AdaptiveEngine.test.ts`

**Interfaces:**
- Produces:

```ts
export type NeedScore = { target: string; score: number; evidenceCount: number };
export type AdaptiveVersion = { id: string; frequencyWeight: number; severityWeight: number; recencyWeight: number; confidenceWeight: number; masteryWeight: number; allocation: { focus1: number; focus2: number; consolidation: number } };
export function rankNeeds(events: PronunciationError[], history: AttemptSummary[], version: AdaptiveVersion): NeedScore[];
export function selectNextContent(needs: NeedScore[], catalog: ContentItem[], version: AdaptiveVersion, count: number): ContentItem[];
```

- [ ] **Step 1: Write ranking tests**

Frequent/recent/high-severity reliable errors rank higher; low-confidence evidence contributes less; mastered targets decline; empty history yields balanced starter practice.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement `adaptive-pilot-v0` with explicit numeric weights summing to 1**

Seed weights: frequency .30, severity .25, recency .20, confidence .15, mastery .10. Allocation: 40% top focus, 35% second focus, 25% consolidation. Store configuration in code/database and version it; research study freeze selects a database adaptive version.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 7: Add Today’s Practice recommendations

**Files:**
- Create: `src/components/practice/TodaysPractice.tsx`
- Modify: `src/pages/student/StudentDashboard.tsx`
- Create: `tests/unit/practice/TodaysPractice.test.tsx`

**Interfaces:**
- Consumes AdaptiveEngine output.
- Produces target mix and links into appropriate Labs.

- [ ] **Step 1: Write UI test for focus explanation**

Example expectation: `Final /s/ — ưu tiên hôm nay vì đây là lỗi xuất hiện thường xuyên trong các lần luyện gần đây.`

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement component with no unsupported causal claims**
- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 8: Implement research test-mode policy

**Files:**
- Create: `src/research/testMode.ts`
- Create: `tests/unit/practice/testMode.test.ts`

**Interfaces:**
- Produces:

```ts
export type TestPolicy = { showDetailedFeedback: boolean; allowImmediateRetry: boolean; allowAdaptivePractice: boolean; lockedAccent: 'us'|'uk'; scoringVersionId: string; contentVersionId: string; referenceVersionIds: string[] };
export function policyForParticipant(snapshot: ResearchSnapshot, participant: StudyParticipant, phase: 'pre'|'intervention'|'post'): TestPolicy;
```

- [ ] **Step 1: Write policy tests**

Pre/post: detailed feedback false, immediate retry false. Experimental intervention: adaptive true. Control intervention: adaptive false. Accent/version values come only from frozen snapshot/participant assignment.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement pure policy function**
- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 9: Enforce cohort access on the database as well as UI

**Files:**
- Create: `supabase/migrations/006_research_intervention_guard.sql`
- Create: `tests/sql/006_research_intervention_guard.sql`

**Interfaces:**
- Produces SQL constraint/RPC logic that rejects control-group `phase='intervention'` adaptive attempts during a frozen/active study.

- [ ] **Step 1: Write SQL tests proving a modified client cannot bypass the restriction**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Add database guard/validated attempt RPC**
- [ ] **Step 4: Run SQL tests**
- [ ] **Step 5: Commit**

### Task 10: Build pre-test/post-test student flow

**Files:**
- Create: `src/pages/student/ResearchStatusPage.tsx`
- Create: `src/pages/student/TestSessionPage.tsx`
- Create: `tests/e2e/research-test-mode.spec.ts`
- Modify: `src/app/routes.tsx`

**Interfaces:**
- Consumes frozen study/test policy and practice orchestration.
- Produces `/student/research` and `/student/research/test/:phase`.

- [ ] **Step 1: Write E2E test**

Experimental student: completes pre-test without detailed feedback/retry -> intervention becomes available -> post-test later. Control student: pre/post available but adaptive intervention route/API remains blocked.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement research status/test pages**

Record device/browser metadata and required versions with every test attempt. A frozen-study configuration mismatch blocks submission and shows an explicit error rather than falling back to current app defaults.

- [ ] **Step 4: Run `npm test && npm run test:e2e -- student-practice.spec.ts research-test-mode.spec.ts && npm run build`**
- [ ] **Step 5: Commit**

## Student/adaptive exit criteria

A student can complete all three controlled-reading modes, receive explainable bilingual feedback, view progress/error patterns, get deterministic personalized recommendations, and complete research pre/post sessions with accent/version locks. A control participant cannot gain adaptive intervention access by editing the frontend.