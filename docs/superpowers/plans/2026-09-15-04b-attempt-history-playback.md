# SpeakSense Student Attempt History and Authorized Playback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the student MVP contract by exposing the student's own attempt history and short-lived authorized playback for recordings that were retained by consent/policy.

**Architecture:** Attempt history is fetched through RLS-scoped queries. Playback URLs are requested on demand from `StorageService` and expire quickly; no signed URL is persisted in local history/state beyond the active playback session.

**Tech Stack:** React, TypeScript, Supabase, existing `StorageService`, Vitest, Playwright.

**Spec:** `docs/superpowers/specs/2026-09-15-speaksense-design.md`

## Global Constraints

- Student can access only their own attempts/audio.
- Audio playback is available only when an `audio_path` exists and retention consent/policy allows it.
- Signed URLs are short-lived and never exported as research data.
- Deleted audio must render as unavailable while structured scores/history may remain.

---

### Task 1: Add student attempt-history service

**Files:**
- Create: `src/student/attemptHistoryService.ts`
- Create: `tests/unit/practice/attemptHistoryService.test.ts`

**Interfaces:**
- Produces `listOwnAttempts({ limit, cursor })` with content label, date, mode, overall/six scores, confidence, sync status, and `hasRetainedAudio` boolean.

- [ ] **Step 1: Write own-data and pagination tests**
- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement RLS-scoped query without exposing raw storage paths to unrelated UI code**
- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 2: Build history and on-demand playback UI

**Files:**
- Create: `src/pages/student/AttemptHistoryPage.tsx`
- Create: `src/components/history/AttemptHistoryRow.tsx`
- Modify: `src/app/routes.tsx`
- Create: `tests/e2e/student-history-playback.spec.ts`

**Interfaces:**
- Consumes attempt history and `StorageService.createPlaybackUrl()`.
- Produces `/student/history`.

- [ ] **Step 1: Write E2E test**

Student sees only own attempts; retained recording gets an on-demand playable signed URL; deleted/non-retained audio shows `Không còn bản ghi âm` while scores remain; Student A cannot request Student B playback.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement history page and revoke/drop playback URL from component state after playback/unmount**
- [ ] **Step 4: Run `npm test && npm run test:e2e -- student-history-playback.spec.ts && npm run build`**
- [ ] **Step 5: Commit**

## History/playback exit criteria

Students can review their own historical scores and replay only recordings they are authorized to access; expired/deleted/non-retained recordings fail safely without losing structured research history.