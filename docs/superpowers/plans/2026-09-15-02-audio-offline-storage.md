# SpeakSense Audio, Offline Queue, and Private Storage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add reliable phone/laptop recording, audio quality checks, local PCM preprocessing, private audio retention, signed playback, and an IndexedDB pending-sync queue that survives temporary network loss.

**Architecture:** The browser captures and preprocesses audio locally. Structured attempt data and retained audio are queued locally first, then synchronized to Supabase when connectivity permits. Supabase Storage remains private; signed URLs are generated only for authorized playback.

**Tech Stack:** Web Media APIs, Web Audio API, AudioWorklet where supported, Dexie/IndexedDB, Supabase Storage, React, TypeScript, Vitest, Playwright.

**Spec:** `docs/superpowers/specs/2026-09-15-speaksense-design.md`

## Global Constraints

- Core analysis workflow must continue offline after required assets are cached.
- Persist Opus/WebM where supported; analysis may use mono PCM in memory.
- Low-quality audio must produce a retry state, not a normal research score.
- Audio bucket must be private; no permanent public URL.
- Students may access only their own audio; teachers only authorized class/research audio.
- Pending-sync states must be explicit: analyzed locally, waiting, syncing, synced, failed.

---

## File map

- `src/audio/AudioEngine.ts` — capture lifecycle and browser capability checks.
- `src/audio/preprocess.ts` — PCM conversion, trim, normalization, quality metrics.
- `src/audio/types.ts` — stable audio interfaces.
- `src/audio/quality.ts` — quality thresholds and retry decision.
- `src/sync/db.ts` — Dexie schema.
- `src/sync/SyncQueue.ts` — enqueue/retry/reconcile.
- `src/storage/StorageService.ts` — upload, signed playback, deletion request functions.
- `src/components/recorder/RecorderPanel.tsx` — accessible recorder UI.
- `supabase/migrations/005_audio_storage.sql` — storage policies/audit records.
- `tests/unit/audio/*` and `tests/e2e/audio-offline.spec.ts`.

### Task 1: Define stable audio-domain interfaces

**Files:**
- Create: `src/audio/types.ts`
- Create: `tests/unit/audio/types.test.ts`

**Interfaces:**
- Produces:

```ts
export type AudioQuality = {
  peakDbfs: number;
  rmsDbfs: number;
  clippedFraction: number;
  leadingSilenceMs: number;
  trailingSilenceMs: number;
  usableDurationMs: number;
};

export type PreparedAudio = {
  pcm: Float32Array;
  sampleRate: 16000;
  durationMs: number;
  quality: AudioQuality;
};

export type QualityDecision =
  | { ok: true }
  | { ok: false; reason: 'too_quiet'|'clipped'|'too_short'|'too_noisy_or_unstable' };
```

- [ ] **Step 1: Write type-level/behavioral tests for quality decisions**
- [ ] **Step 2: Run `npm test -- tests/unit/audio/types.test.ts` and verify failure**
- [ ] **Step 3: Add the types and deterministic thresholds in `quality.ts`**

Initial thresholds must be explicit constants, e.g. minimum usable duration 500 ms, clipping fraction <= 0.01, and configurable RMS/peak bounds. Store them in one exported `AUDIO_QUALITY_V1` object so research versions can later reference them.

- [ ] **Step 4: Run tests and verify pass**
- [ ] **Step 5: Commit**

```bash
git add src/audio tests/unit/audio
git commit -m "feat: define audio quality contract"
```

### Task 2: Implement browser recording capability and capture lifecycle

**Files:**
- Create: `src/audio/AudioEngine.ts`
- Create: `tests/unit/audio/AudioEngine.test.ts`

**Interfaces:**
- Produces:

```ts
export interface AudioEngine {
  getCapabilities(): Promise<{ microphone: boolean; mimeType: string | null }>;
  start(): Promise<void>;
  stop(): Promise<{ blob: Blob; mimeType: string; recordedAt: string }>;
  cancel(): Promise<void>;
}
```

- [ ] **Step 1: Write tests with mocked `navigator.mediaDevices` and `MediaRecorder`**

Test microphone denial, unsupported codec fallback, start/stop, and cancel releasing all tracks.

- [ ] **Step 2: Run test and verify failure**

Run: `npm test -- AudioEngine.test.ts`
Expected: FAIL.

- [ ] **Step 3: Implement codec negotiation**

Try `audio/webm;codecs=opus`, then `audio/webm`, then any supported browser MediaRecorder type. If no safe type exists, return an explicit unsupported state rather than silently recording unknown data.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

```bash
git add src/audio/AudioEngine.ts tests/unit/audio/AudioEngine.test.ts
git commit -m "feat: add cross-browser audio capture"
```

### Task 3: Implement PCM preprocessing and quality metrics

**Files:**
- Create: `src/audio/preprocess.ts`
- Create: `src/audio/quality.ts`
- Create: `tests/unit/audio/preprocess.test.ts`

**Interfaces:**
- Produces: `prepareAudio(blob: Blob): Promise<PreparedAudio>` and `evaluateQuality(q: AudioQuality): QualityDecision`.

- [ ] **Step 1: Add fixture-generated sine/silence/clipping tests**

Generate arrays in test code; do not commit personal voice data. Verify resampling target 16 kHz, mono shape, silence trim, normalization bounds, and clipping detection.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement decode/resample/trim/normalize functions as small pure helpers**

Do not persist PCM. `PreparedAudio.pcm` exists only in memory and may be transferred to a worker in later scoring work.

- [ ] **Step 4: Run tests and benchmark a 60-second synthetic clip under desktop Chromium**
- [ ] **Step 5: Commit**

```bash
git add src/audio/preprocess.ts src/audio/quality.ts tests/unit/audio/preprocess.test.ts
git commit -m "feat: preprocess and validate recordings"
```

### Task 4: Add recorder UI with explicit recoverable states

**Files:**
- Create: `src/components/recorder/RecorderPanel.tsx`
- Create: `src/components/recorder/recorderMachine.ts`
- Create: `tests/unit/recorderMachine.test.ts`

**Interfaces:**
- Produces state machine: `idle -> requesting -> recording -> preparing -> ready|retry|error`.

- [ ] **Step 1: Write state transition tests**

Test denied permission, stop success, low-quality retry, and cancellation.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement state machine and accessible UI**

UI must include text labels; do not rely on color. Permission denial copy must tell the user how to retry after enabling microphone access.

- [ ] **Step 4: Run unit tests and manual keyboard test**
- [ ] **Step 5: Commit**

### Task 5: Implement IndexedDB pending-sync queue

**Files:**
- Create: `src/sync/db.ts`
- Create: `src/sync/SyncQueue.ts`
- Create: `tests/unit/SyncQueue.test.ts`

**Interfaces:**
- Produces:

```ts
export type SyncState = 'pending'|'syncing'|'synced'|'failed';
export type PendingAttempt = {
  localId: string;
  attempt: Record<string, unknown>;
  audioBlob?: Blob;
  state: SyncState;
  retryCount: number;
  lastError?: string;
};

export interface SyncQueue {
  enqueue(item: PendingAttempt): Promise<void>;
  flush(): Promise<void>;
  retry(localId: string): Promise<void>;
  listPending(): Promise<PendingAttempt[]>;
}
```

- [ ] **Step 1: Write tests using fake IndexedDB**

Prove a queued attempt survives service recreation, successful sync removes/marks item, failure retains it, and duplicate local IDs are idempotent.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement Dexie schema and queue with exponential backoff capped at five attempts per automatic cycle**
- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

```bash
git add src/sync tests/unit/SyncQueue.test.ts
git commit -m "feat: persist offline sync queue"
```

### Task 6: Create private audio storage policies and upload service

**Files:**
- Create: `supabase/migrations/005_audio_storage.sql`
- Create: `src/storage/StorageService.ts`
- Create: `tests/sql/005_audio_storage.sql`
- Create: `tests/unit/StorageService.test.ts`

**Interfaces:**
- Produces:
  - `uploadAttemptAudio(input): Promise<{ path: string }>`
  - `createPlaybackUrl(path: string): Promise<string>`
  - `deleteAttemptAudio(path: string): Promise<void>`

- [ ] **Step 1: Write storage authorization assertions**

Student A cannot fetch Student B object; unrelated teacher cannot fetch; authorized teacher can fetch class/research audio; public/anonymous access fails.

- [ ] **Step 2: Verify failure before policies**
- [ ] **Step 3: Create private `research-audio` bucket/policies**

Object path must be `research/<study-id>/<student-id>/<attempt-id>.<ext>` for study recordings and an equivalent user-private namespace for non-study practice. Signed URLs should default to a short TTL such as 120 seconds.

- [ ] **Step 4: Run storage policy and service tests**
- [ ] **Step 5: Commit**

### Task 7: Reconcile partial sync failures

**Files:**
- Modify: `src/sync/SyncQueue.ts`
- Create: `src/sync/reconcileAttempt.ts`
- Create: `tests/unit/reconcileAttempt.test.ts`

**Interfaces:**
- Produces idempotent `reconcileAttempt(localId)` that can recover from: metadata created/audio missing, audio uploaded/metadata finalization failed, and repeated retry.

- [ ] **Step 1: Write three partial-failure tests**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement two-phase sync using a stable client-generated UUID for `attempts.id`**

Sequence: upsert structured attempt as `upload_pending` -> upload object -> update `audio_path` and `sync_state='synced'`. Re-running the same local ID must not duplicate attempts.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 8: Add offline/reconnect E2E coverage

**Files:**
- Create: `tests/e2e/audio-offline.spec.ts`
- Modify: `src/pages/student/StudentDashboard.tsx`

**Interfaces:**
- Consumes recorder, queue, storage service.
- Produces visible sync status cards used later by practice pages.

- [ ] **Step 1: Write Playwright test**

Flow: sign in -> simulate offline -> record/test fixture through injected media mock -> local result enters waiting state -> reload -> item remains -> restore network -> flush -> synced state.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Wire queue status UI and connectivity trigger**
- [ ] **Step 4: Run `npm test && npm run test:e2e -- audio-offline.spec.ts && npm run build`**
Expected: PASS.
- [ ] **Step 5: Commit**

## Audio/offline exit criteria

A student can make a valid recording on supported mobile/desktop browsers, poor recordings are rejected before scoring, a valid recording can be retained privately, offline attempts persist across reload, and reconnect synchronizes idempotently without exposing public audio URLs.