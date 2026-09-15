# SpeakSense Acoustic Model, Alignment, and Scoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a browser-local, explainable pronunciation pipeline that turns a valid 16 kHz recording plus a controlled US/UK reference into alignment evidence, six component scores, structured Vietnamese-learner error events, confidence, and bilingual feedback metadata without paid APIs.

**Architecture:** Run an open-source Wav2Vec2 CTC phoneme model in a Web Worker through Transformers.js/ONNX Runtime Web. Keep the model behind `AcousticModelAdapter`; align decoded/frame-level evidence to known reference phonemes with deterministic dynamic programming; derive stress/intonation/fluency features from PCM; score through a versioned pure TypeScript engine.

**Tech Stack:** TypeScript, `@huggingface/transformers`, ONNX Runtime Web, Web Worker, Vitest. Candidate Apache-2.0 ONNX phoneme models for the feasibility gate: `onnx-community/wav2vec2-ljspeech-gruut-ONNX` (prefer q4f16/q4 artifacts) and `onnx-community/wav2vec2-lv-60-espeak-cv-ft-ONNX` (prefer q4f16/q4 artifacts).

**Spec:** `docs/superpowers/specs/2026-09-15-speaksense-design.md`

## Global Constraints

- No metered/paid AI call is allowed in scoring.
- Controlled reading only; free speaking is out of scope.
- Acoustic model must be replaceable behind `AcousticModelAdapter`.
- US/UK references are separately versioned.
- Every attempt yields Phoneme Accuracy, Final Sounds, Word Stress, Sentence Stress, Intonation, Fluency, overall score, confidence, and structured error evidence when quality/model confidence permits.
- Research scoring configuration is immutable after study freeze.
- Low-confidence evidence must be labeled, not overclaimed.
- A model feasibility failure is a hard gate: do not fake phoneme scores from text similarity.

---

## File map

- `src/scoring/model/AcousticModelAdapter.ts` — stable inference interface.
- `src/scoring/model/TransformersPhonemeAdapter.ts` — selected browser model adapter.
- `src/scoring/model/model.worker.ts` — worker-owned model lifecycle.
- `src/scoring/model/modelRegistry.ts` — explicit candidate/selected artifacts.
- `src/scoring/alignment/AlignmentEngine.ts` — deterministic reference-observation alignment.
- `src/scoring/features/prosody.ts` — pitch, energy, duration, pause features.
- `src/scoring/features/yin.ts` — F0 estimator.
- `src/scoring/ScoringEngine.ts` — pure score calculation.
- `src/scoring/ErrorModel.ts` — Vietnamese learner error-family mapping.
- `src/scoring/confidence.ts` — confidence calculation.
- `src/scoring/types.ts` — contracts shared by UI/storage.
- `src/references/schema.ts`, `src/references/seed/*.json` — versioned US/UK controlled references.
- `scripts/benchmark-acoustic-model.mjs` — benchmark runner.
- `docs/benchmarks/acoustic-model-2026-09.md` — measured selection record.
- `tests/unit/scoring/*` — deterministic fixtures and scoring tests.

### Task 1: Build the acoustic-model feasibility benchmark before product integration

**Files:**
- Create: `src/scoring/model/modelRegistry.ts`
- Create: `scripts/benchmark-acoustic-model.mjs`
- Create: `docs/benchmarks/acoustic-model-2026-09.md`
- Create: `tests/unit/scoring/modelRegistry.test.ts`

**Interfaces:**
- Produces `MODEL_CANDIDATES` with exact model id, artifact preference, label scheme, license, and 16 kHz requirement.

Candidate registry:

```ts
export const MODEL_CANDIDATES = [
  {
    id: 'onnx-community/wav2vec2-ljspeech-gruut-ONNX',
    preferredDtype: 'q4f16',
    fallbackDtype: 'q4',
    labelScheme: 'gruut-phoneme',
    license: 'apache-2.0',
    sampleRate: 16000,
  },
  {
    id: 'onnx-community/wav2vec2-lv-60-espeak-cv-ft-ONNX',
    preferredDtype: 'q4f16',
    fallbackDtype: 'q4',
    labelScheme: 'espeak-phoneme',
    license: 'apache-2.0',
    sampleRate: 16000,
  },
] as const;
```

- [ ] **Step 1: Write registry tests**

Require unique IDs, Apache-2.0 metadata, 16 kHz input, and an explicit label scheme.

- [ ] **Step 2: Run test and verify failure**
- [ ] **Step 3: Implement benchmark script**

For each candidate/artifact, measure cold model load, cached model load, 5 s/15 s inference time, peak JS heap where observable, output phoneme plausibility on a small consent-free prerecorded/public-domain or synthetic benchmark fixture, and execution provider (`wasm` or `webgpu`). Do not use student research audio in model selection.

Hard acceptance gate for a research candidate:
- loads successfully on iPhone Safari through WASM or a compatible path;
- loads on Android Chrome and desktop Chromium;
- returns phoneme labels rather than word-only text;
- 15-second clip completes in <= 30 seconds on the slowest accepted research device;
- no browser crash/reload during three consecutive inferences;
- cached reload succeeds offline after assets are cached.

- [ ] **Step 4: Run the benchmark on representative iPhone, Android, and laptop and record real values in `docs/benchmarks/acoustic-model-2026-09.md`**

The selected model must be named explicitly in the benchmark document. If neither candidate passes, stop this plan and revise architecture; do not continue with invented phoneme scores.

- [ ] **Step 5: Commit**

```bash
git add src/scoring/model/modelRegistry.ts scripts/benchmark-acoustic-model.mjs docs/benchmarks tests/unit/scoring/modelRegistry.test.ts
git commit -m "test: benchmark browser phoneme models"
```

### Task 2: Define scoring-domain contracts

**Files:**
- Create: `src/scoring/types.ts`
- Create: `tests/unit/scoring/types.test.ts`

**Interfaces:**
- Produces:

```ts
export type PhonemeFrame = { token: string; startMs: number; endMs: number; confidence: number };
export type AcousticResult = { frames: PhonemeFrame[]; modelId: string; runtime: 'wasm'|'webgpu'; inferenceMs: number };
export type AlignmentKind = 'match'|'substitution'|'deletion'|'insertion'|'low_confidence';
export type AlignmentUnit = { expected?: string; observed?: string; kind: AlignmentKind; startMs?: number; endMs?: number; confidence: number; wordIndex?: number };
export type ComponentScores = { phonemeAccuracy: number; finalSounds: number; wordStress: number; sentenceStress: number; intonation: number; fluency: number };
export type ScoreResult = { overall: number; components: ComponentScores; confidence: number; confidenceBand: 'high'|'medium'|'low'; errors: PronunciationError[]; metrics: Record<string, number> };
```

- [ ] **Step 1: Write tests that clamp all score fields to 0–100 and confidence to 0–1**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Add contracts plus runtime Zod parsers for persisted score payloads**
- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 3: Implement `AcousticModelAdapter` and worker isolation

**Files:**
- Create: `src/scoring/model/AcousticModelAdapter.ts`
- Create: `src/scoring/model/TransformersPhonemeAdapter.ts`
- Create: `src/scoring/model/model.worker.ts`
- Create: `tests/unit/scoring/AcousticModelAdapter.test.ts`

**Interfaces:**
- Produces:

```ts
export interface AcousticModelAdapter {
  load(): Promise<void>;
  infer(pcm16k: Float32Array): Promise<AcousticResult>;
  dispose(): Promise<void>;
  getModelId(): string;
}
```

- [ ] **Step 1: Write adapter tests against a fake worker transport**

Test load-once behavior, inference request correlation, worker error propagation, dispose, and model metadata.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement the selected benchmark winner using `@huggingface/transformers`**

The worker owns model instances. Main-thread API transfers/copies only required PCM. If WebGPU is supported by the selected browser/model, prefer it on compatible Chromium; use WASM fallback. Do not require WebGPU because iOS Safari may need WASM.

- [ ] **Step 4: Run adapter tests and manual worker smoke test**
- [ ] **Step 5: Commit**

### Task 4: Add versioned US/UK reference data and validation

**Files:**
- Create: `src/references/schema.ts`
- Create: `src/references/seed/word-v1.json`
- Create: `src/references/seed/sentence-v1.json`
- Create: `src/references/seed/passage-v1.json`
- Create: `scripts/validate-references.mjs`
- Create: `tests/unit/scoring/references.test.ts`

**Interfaces:**
- Produces `PronunciationReference` with content id, accent, words, canonical phoneme tokens, syllable boundaries, lexical stress, target tags, and `referenceVersion`.

- [ ] **Step 1: Write reference schema tests**

Every research item must have both `us` and `uk` entries, non-empty phoneme sequences, explicit syllable/stress data where applicable, and immutable version identifiers.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Add a small pilot bank sufficient for engineering tests**

Include controlled targets `/θ/`, `/ð/`, final `/s/`, `/z/`, `/t/`, `/d/`, at least two stress targets, at least two sentence intonation patterns, and one 40–80 word passage. Research test-bank expansion occurs through Content Bank later, but references must use this exact schema.

- [ ] **Step 4: Run `node scripts/validate-references.mjs` and unit tests**
- [ ] **Step 5: Commit**

### Task 5: Implement deterministic phoneme alignment

**Files:**
- Create: `src/scoring/alignment/AlignmentEngine.ts`
- Create: `tests/unit/scoring/AlignmentEngine.test.ts`

**Interfaces:**
- Produces `alignPhonemes(expected: ReferenceToken[], observed: PhonemeFrame[]): AlignmentUnit[]`.

- [ ] **Step 1: Write alignment fixtures**

Include exact match, `/θ/ -> /t/`, missing final `/s/`, extra segment, and low-confidence frame.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement dynamic-programming alignment**

Use deterministic edit costs. Confidence below the versioned threshold converts a nominal match/substitution into `low_confidence`; do not force a confident label from weak evidence. Preserve observed time spans for later prosody windows.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 6: Implement prosody features

**Files:**
- Create: `src/scoring/features/yin.ts`
- Create: `src/scoring/features/prosody.ts`
- Create: `tests/unit/scoring/prosody.test.ts`

**Interfaces:**
- Produces:

```ts
export type ProsodyFeatures = {
  syllableEnergy: number[];
  syllableDurationMs: number[];
  syllablePitchHz: Array<number|null>;
  pitchContourHz: Array<number|null>;
  pauseRatio: number;
  unexpectedPauseCount: number;
  articulationRate: number;
  speechRate: number;
};
```

- [ ] **Step 1: Write synthetic-tone/pause tests**

Use generated signals to prove F0 estimator approximately identifies 120/220 Hz tones, energy ranking, and pause ratio.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement YIN/autocorrelation-style F0 plus RMS/pause calculations**

Unvoiced frames return `null`; do not replace them with zero pitch. Derive syllable windows from aligned reference spans when available.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 7: Implement six component scores and overall versioned scoring

**Files:**
- Create: `src/scoring/ScoringEngine.ts`
- Create: `src/scoring/scoringVersions.ts`
- Create: `tests/unit/scoring/ScoringEngine.test.ts`

**Interfaces:**
- Produces:

```ts
export type ScoringVersion = {
  id: string;
  weights: ComponentScores;
  thresholds: { lowAlignmentConfidence: number; highResultConfidence: number; mediumResultConfidence: number };
};
export function scoreAttempt(input: ScoreInput, version: ScoringVersion): ScoreResult;
```

- [ ] **Step 1: Write score-bound and monotonicity tests**

Better alignment cannot reduce phoneme score; removing a correct final consonant must reduce final-sounds score; extra unexpected pauses must not improve fluency; all scores remain 0–100.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement `pilot-v0` as a non-research calibration profile**

Use equal component weights for `pilot-v0` (1/6 each). Do not silently promote `pilot-v0` to the research scoring version. The Admin/research freeze flow must require an explicitly saved/frozen database scoring version before pre-test.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 8: Implement Vietnamese learner error mapping and bilingual feedback metadata

**Files:**
- Create: `src/scoring/ErrorModel.ts`
- Create: `src/scoring/feedback.ts`
- Create: `tests/unit/scoring/ErrorModel.test.ts`

**Interfaces:**
- Produces `mapErrors(alignment, reference): PronunciationError[]` and `feedbackForError(error, locale='vi-en')`.

- [ ] **Step 1: Write fixtures for `/θ/→/t/`, `/ð/→/d/`, final `/s z t d/` omissions and stress error**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement conservative mapping**

Only emit a specific substitution family when observed evidence exceeds the family confidence threshold. Otherwise emit a generic `phoneme_uncertain` event. Feedback text must say “may sound like /t/” or equivalent when uncertainty remains; never claim perfect diagnosis.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 9: Implement result confidence and persistence-ready scoring payload

**Files:**
- Create: `src/scoring/confidence.ts`
- Create: `src/scoring/scoreAttempt.ts`
- Create: `tests/unit/scoring/scoreAttempt.test.ts`

**Interfaces:**
- Produces `analyzeAndScore(preparedAudio, reference, scoringVersion, adapter): Promise<ScoreResult>`.

- [ ] **Step 1: Write integration-style unit test with fake adapter output**

Verify quality passes -> alignment -> prosody -> six scores -> overall -> confidence -> errors. Verify weak model evidence -> low confidence, not a high-confidence precise error.

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement orchestration with no UI dependencies**
- [ ] **Step 4: Run all scoring tests and build**

Run: `npm test -- tests/unit/scoring && npm run build`
Expected: PASS.

- [ ] **Step 5: Commit**

## Scoring exit criteria

At least one documented browser phoneme model passes the feasibility gate on representative iPhone/Android/laptop devices; a controlled word/sentence/passage fixture produces reproducible alignment, six scores, confidence, and conservative error events entirely in-browser; no paid service is invoked; model/scoring/reference identifiers are present in the persistable result.