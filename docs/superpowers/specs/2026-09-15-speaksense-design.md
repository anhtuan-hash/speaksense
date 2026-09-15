# SpeakSense — Design Specification

**Date:** 2026-09-15  
**Status:** Approved design, ready for implementation planning  
**Repository:** `anhtuan-hash/speaksense`  
**Product type:** Standalone browser-first web/PWA  
**Primary use case:** English pronunciation training and research with Vietnamese high-school students

## 1. Project objective

SpeakSense is a standalone pronunciation-training platform designed for Vietnamese high-school students. Its core research question is whether a browser-based adaptive pronunciation system can improve measurable pronunciation outcomes compared with normal pronunciation practice, while remaining usable without paid AI APIs.

The product must serve two purposes at the same time:

1. be a credible, usable educational product for students and teachers; and
2. generate traceable, reproducible research evidence suitable for the 2026–2027 Ho Chi Minh City science and engineering competition.

The system must not be positioned as a perfect or diagnostic pronunciation judge. Automated scores are learning-support estimates and must be validated against human assessment.

## 2. Competition constraints that shape the product

The project is being prepared for the Ho Chi Minh City secondary-student science and engineering competition, school year 2026–2027.

The design therefore prioritizes:

- a clearly stated technical/research problem;
- explicit research design and methodology;
- actual implementation and testing;
- measurable data collection and analysis;
- creativity and novelty;
- a demonstrable product that can be explained and defended in an interview;
- traceability through research logs, scoring versions, test versions, and stored evidence.

The submission window is 05/10/2026–10/10/2026, so the first research-ready MVP must be operational before 05/10/2026.

## 3. Target users and roles

### 3.1 Student

Students use a username and password. They do not need personal email addresses.

Students can:

- join a teacher-created class using a class code;
- select an English accent profile when entering a research study;
- practice words, sentences, and short passages;
- record audio using phone or laptop microphones;
- receive six component scores and an overall score;
- view bilingual English–Vietnamese feedback;
- see their pronunciation-error map and progress;
- receive adaptive practice recommendations;
- complete pre-test and post-test activities;
- replay their own retained recordings.

Students cannot view other students' records or research data.

### 3.2 Teacher

Teachers authenticate with email and password.

Teachers can:

- create classes and class codes;
- manage class membership;
- view class-level analytics;
- view student-level pronunciation history for their own classes;
- review retained recordings;
- conduct blind human validation;
- manage approved content banks for their classes;
- view research-study progress;
- export de-identified research data.

### 3.3 Admin

Admins authenticate with email and password.

Admins can:

- manage teacher accounts;
- create and freeze research studies;
- manage scoring-engine versions;
- manage test/reference versions;
- manage audio-retention policy;
- publish canonical content/reference sets;
- delete retained audio according to policy;
- inspect system health and research integrity.

## 4. Research design

### 4.1 Primary population

The primary research population is Grade 11.

Grades 10 and 12 may use SpeakSense as normal users, but their records are not mixed into the principal Grade 11 experimental analysis unless a later study explicitly defines them as participants.

### 4.2 Study structure

The initial study uses a quasi-experimental two-group design:

- approximately 30 students in a control class;
- approximately 30 students in an experimental class;
- both classes complete the same pre-test;
- the experimental class uses SpeakSense adaptive practice for three intensive weeks;
- the control class follows normal pronunciation-learning practice during the same period;
- both classes complete the same-equivalence post-test;
- baseline equivalence between the two intact classes is checked using pre-test results.

The three-week intervention is chosen because of the October 2026 competition submission deadline. Data collection may continue after submission to provide longer-term evidence for later interview rounds.

### 4.3 Accent assignment

SpeakSense supports:

- General American English;
- British English.

A participant chooses one accent for a study. That choice is frozen for the study and cannot be changed between pre-test and post-test.

Reference phonemes, lexical stress, and other accent-dependent data are versioned separately for US and UK profiles.

### 4.4 Human validation

Approximately 20–30% of research recordings are selected for blind human review.

Reviewers must not see the automated score before submitting their own rating. After human submission, the system may reveal the SpeakSense score and calculate agreement measures.

Planned validation metrics include:

- mean absolute error;
- correlation between human and automated scores;
- proportion of automated scores within ±5 points of human scores;
- error by scoring component;
- error by target phoneme/error family;
- performance by confidence level.

## 5. Product principles

1. **AI operating cost must be 0 VND.** Core scoring must not depend on paid OpenAI, Google, Azure, or similar metered APIs.
2. **Browser-first.** Core recording and scoring should run locally in the browser where practical.
3. **Mobile and laptop support.** The app must work on common iPhone, Android, Windows, and macOS browsers.
4. **Research reproducibility.** Every research score must identify the scoring, content, and reference versions used.
5. **Explainable scoring.** No unexplained single “AI score”.
6. **Privacy by default.** Audio is private, time-limited, and access-controlled.
7. **Graceful uncertainty.** Low-quality or low-confidence recordings must be flagged instead of being presented as reliable measurements.
8. **No feature inflation before competition.** Research-critical functionality takes precedence over social, chatbot, and gamification features.

## 6. High-level architecture

SpeakSense consists of two major layers.

### 6.1 Browser layer

The browser performs the learning-critical pipeline:

`Microphone -> Audio Preprocessing -> Acoustic Inference -> Alignment -> Scoring -> Feedback -> Adaptive Recommendation`

Main browser modules:

- PWA shell;
- Student UI;
- Teacher/Admin UI;
- Audio Engine;
- Acoustic Model Adapter;
- Forced Alignment Engine;
- Pronunciation Scoring Engine;
- Vietnamese Learner Error Model;
- Adaptive Practice Engine;
- local IndexedDB sync queue;
- Supabase data/storage client.

### 6.2 Cloud layer

Supabase provides:

- authentication;
- PostgreSQL database;
- Row Level Security;
- private audio storage;
- research metadata;
- class membership;
- human reviews;
- de-identified exports.

The cloud must not be required to calculate the primary pronunciation score during a normal practice attempt.

## 7. Audio-processing pipeline

### 7.1 Capture

Audio is recorded using browser microphone APIs.

Preferred persisted recording format:

- Opus/WebM where supported.

Temporary analysis audio may be converted to mono PCM in memory.

### 7.2 Preprocessing

The Audio Engine should perform:

- mono conversion;
- sample-rate normalization;
- removal of leading/trailing silence;
- level normalization;
- basic noise/quality checks;
- detection of recordings that are too quiet, clipped, or unusably noisy.

If quality is below an acceptable threshold, SpeakSense returns a retry state instead of a normal score.

Example message:

> Recording quality is too low. Please retry in a quieter place.

### 7.3 Acoustic model

The model must be:

- open source;
- usable without metered API calls;
- compatible with browser inference through ONNX Runtime Web, WebAssembly, WebGPU, or an equivalent open runtime;
- quantized/lightweight enough for mobile use;
- lazy-loaded;
- cacheable after first download.

The exact model is intentionally not frozen in this specification. During implementation, candidate models will be benchmarked on representative iPhone, Android, and laptop hardware.

Selection criteria:

- phoneme/alignment usefulness;
- model size;
- first-load time;
- inference latency;
- memory consumption;
- mobile compatibility;
- license suitability.

The rest of SpeakSense must use an `AcousticModelAdapter` interface so that the selected model can later be replaced without rewriting scoring logic.

### 7.4 Forced alignment

SpeakSense primarily scores controlled reading, not open-ended speech.

Because the expected word/sentence/passage is known, the system aligns observed acoustic/phonetic evidence to a reference pronunciation.

Alignment output should distinguish at least:

- match;
- substitution;
- deletion;
- possible insertion;
- low-confidence segment.

Example:

- expected `/θ/`, observed evidence closer to `/t/` -> substitution candidate;
- expected final `/s/`, no aligned segment -> final-sound omission candidate.

## 8. Reference pronunciation data

Each content item should support US and UK reference records containing, where applicable:

- orthographic text;
- word boundaries;
- canonical phoneme sequence;
- syllable boundaries;
- lexical stress;
- target error tags;
- expected duration/pausing metadata where useful;
- reference version.

References must be versioned. Research runs must point to immutable reference versions.

## 9. Pronunciation Scoring Engine

The Scoring Engine is a standalone domain module independent of UI.

Conceptual interface:

`audio features + alignment + reference + scoring version -> scores + error events + confidence + feedback metadata`

### 9.1 Component scores

Every scored attempt produces six 0–100 component scores:

1. **Phoneme Accuracy**
2. **Final Sounds**
3. **Word Stress**
4. **Sentence Stress**
5. **Intonation**
6. **Fluency**

An overall 0–100 score is calculated from versioned weights.

### 9.2 Phoneme Accuracy

Uses phoneme-level alignment/probability evidence against the canonical reference.

The engine records likely substitutions, deletions, and uncertain segments.

### 9.3 Final Sounds

Separately evaluates word-final consonants and relevant consonant clusters, because final-consonant omission is a key Vietnamese learner error family.

### 9.4 Word Stress

Uses syllable-level acoustic features such as relative energy, duration, and pitch where feasible.

### 9.5 Sentence Stress

Evaluates relative prominence patterns of expected content words and stress groups for controlled sentences/passages.

### 9.6 Intonation

Evaluates pitch contour characteristics relative to the target pattern appropriate to the controlled text.

### 9.7 Fluency

May include:

- speaking rate;
- articulation rate;
- pause ratio;
- unexpected pause count;
- excessive hesitation;
- rhythm consistency.

### 9.8 Overall score

Weights belong to a `scoring_versions` record, not hard-coded business logic.

Once a research study is frozen, its scoring version cannot change.

## 10. Confidence model

Each automated result includes a confidence category or normalized score.

At minimum:

- High;
- Medium;
- Low.

Low-confidence results should be eligible for human review and should be visibly marked in teacher research views.

The system must never imply equal reliability for all recordings.

## 11. Vietnamese Learner Error Model

SpeakSense maintains structured error families designed around recurring Vietnamese learner patterns.

Initial target families may include:

- `/θ/` realized closer to `/t/`;
- `/ð/` realized closer to `/d/`;
- omission or weakening of final `/s/`;
- omission or weakening of final `/z/`;
- omission or weakening of final `/t/`;
- omission or weakening of final `/d/`;
- selected long/short vowel confusions;
- word-stress errors;
- sentence-stress errors.

This list is extensible and must be empirically refined rather than treated as a fixed claim about every Vietnamese learner.

Each detected error event should store:

- expected unit;
- observed/likely alternative where available;
- error family;
- severity;
- confidence;
- word/content location;
- attempt id;
- scoring version.

## 12. Adaptive Practice Engine

The initial adaptive engine is deterministic and does not require generative AI.

It ranks learner needs using a combination of:

- frequency;
- severity;
- recency;
- confidence;
- mastery/progress trend.

The engine then selects published content tagged with relevant targets.

Example:

- final `/s/` need score = 0.82;
- `/θ/` need score = 0.71;
- word stress need score = 0.34.

A possible next session mix:

- 40% final `/s/`;
- 35% `/θ/`;
- 25% consolidation.

Adaptive selection rules must be versioned if used in the research study.

## 13. Learning modes

### 13.1 Word Lab

Designed for isolated phonemes, minimal pairs, syllables, and final consonants.

### 13.2 Sentence Lab

Adds lexical stress, sentence stress, connected speech, and intonation.

### 13.3 Passage Lab

Uses short controlled passages, approximately 40–80 words for the MVP, to evaluate fluency, rhythm, pausing, and stability across continuous speech.

### 13.4 Out of scope for MVP

Free speaking is intentionally excluded from the competition MVP because it reduces experimental control and substantially increases scoring complexity.

## 14. Student feedback

Feedback is bilingual English–Vietnamese.

Technical terminology should remain accurate in English, with concise Vietnamese guidance.

Example:

**Final sound /s/ omitted**  
`Em có xu hướng bỏ âm /s/ ở cuối từ. Hãy giữ luồng hơi đến hết từ và đọc lại.`

Feedback should include:

- overall score;
- six component scores;
- word/phoneme-level problem markers where reliable;
- short correction guidance;
- retry option;
- recommended next practice.

Color may be used, but all states must also contain text/icons so meaning is not color-dependent.

## 15. Test mode

Pre-test and post-test use a restricted test mode.

Rules:

- no immediate repetition of the same test item;
- detailed corrective feedback is hidden until the test is complete;
- device/browser metadata is recorded;
- selected accent is recorded and locked;
- scoring version is recorded;
- content/test version is recorded;
- retained audio is stored when research consent permits;
- results are written to the designated research phase.

Control-group participants may use SpeakSense for pre/post data collection but must not gain access to the adaptive intervention during the three-week experimental period.

## 16. Student experience

Main student dashboard sections:

- Today's Practice;
- My Progress;
- My Common Errors;
- Research Status.

Typical practice flow:

`Open assignment -> listen/reference if allowed -> record -> analyze locally -> see scores -> read feedback -> retry/practice next target -> sync`

## 17. Teacher experience

Teacher navigation includes:

- Classes;
- Research;
- Pronunciation Analytics;
- Human Validation;
- Content Bank;
- Export.

Teacher analytics should support:

- participation/completion rate;
- average scores;
- change over time;
- most common error families;
- student-level history;
- class heatmap by error/skill;
- pre-test vs post-test;
- control vs experimental comparison.

## 18. Blind Human Validation UI

A reviewer receives:

- anonymous participant code;
- item/passage identifier;
- audio playback;
- human-rating form.

Automated scores remain hidden until the reviewer submits.

After submission, the system stores:

- reviewer id;
- review timestamp;
- human overall/component scores;
- automated overall/component scores;
- scoring version;
- absolute difference;
- optional notes.

## 19. Research Dashboard

The research dashboard should directly support competition analysis.

Required views include:

- control vs experimental pre-test mean;
- control vs experimental post-test mean;
- mean gain;
- gain by six scoring components;
- weekly progress for experimental group;
- change in targeted error-family frequency;
- practice minutes and attempt counts;
- completion rate;
- AI–human agreement metrics;
- confidence-distribution analysis.

Exports use participant codes such as `S001` rather than real names by default.

## 20. Research freeze and versioning

Before pre-test begins, an admin freezes a `Research Snapshot` containing:

- study id;
- scoring version;
- adaptive-policy version;
- test content version;
- reference version(s);
- cohort assignments;
- participant accent assignments;
- study dates.

Frozen research versions are immutable.

Any later improvement must create a new version rather than silently altering existing research logic.

## 21. Authentication design

### 21.1 Teacher/Admin

Use Supabase email/password authentication.

### 21.2 Student

Students enter a username and password.

Internally, the app maps the username to a synthetic Supabase Auth email namespace, for example:

`11a1_tuananh@students.speaksense.local`

The synthetic email is an implementation detail and is never shown to the student as a required credential.

The platform must not implement its own password hashing/authentication system.

## 22. Class joining

Teacher creates a class -> system generates a class code -> student registers/logs in -> student enters class code -> membership is created if allowed.

Teachers can rotate or disable class codes.

## 23. Data model

Core tables:

### `profiles`

- `id`
- `role` (`student`, `teacher`, `admin`)
- `display_name`
- `username` where applicable
- timestamps

### `classes`

- `id`
- `teacher_id`
- `name`
- `grade`
- `join_code_hash` / join-code metadata
- active status

### `class_members`

- `class_id`
- `student_id`
- membership status
- timestamps

### `research_studies`

- `id`
- name/title
- status
- dates
- frozen snapshot/version references
- retention policy

### `study_participants`

- `study_id`
- `student_id`
- anonymous `participant_code`
- cohort (`control`, `experimental`)
- accent (`us`, `uk`)
- participation status

### `content_items`

- `id`
- type (`word`, `sentence`, `passage`)
- text
- level/grade metadata
- target tags
- publish status
- content version

### `pronunciation_references`

- content id
- accent
- phonemes
- syllables
- stress metadata
- reference version

### `attempts`

- `id`
- `student_id`
- content id
- study/phase where applicable
- accent
- device/browser metadata
- audio path/status
- timestamps
- sync state
- scoring version

### `attempt_scores`

- attempt id
- overall score
- six component scores
- confidence
- relevant raw/normalized metrics needed for reproducibility

### `pronunciation_errors`

- attempt id
- error family
- expected unit
- observed/likely unit
- position
- severity
- confidence

### `human_reviews`

- attempt id
- reviewer id
- human scores
- automated snapshot scores
- differences
- notes
- timestamps

### `scoring_versions`

- version id/name
- component weights
- thresholds
- algorithm metadata
- status
- created/frozen timestamps

### `adaptive_versions`

- version id/name
- need-score rules
- content-allocation rules
- status

### `consent_records`

- participant/student id
- study id
- consent status
- audio-retention permission
- consent version
- timestamp

## 24. Row Level Security

RLS is mandatory.

### Student

May access only:

- own profile;
- own membership;
- own attempts/scores/errors;
- own eligible study status;
- own private recordings through authorized signed access.

### Teacher

May access:

- classes they own/manage;
- members of those classes;
- relevant student attempts/scores/errors;
- audio for valid instructional/research purposes;
- human-review queue assigned or permitted to them;
- de-identified exports for their studies/classes.

### Admin

May manage research configuration, teacher accounts, canonical content/reference sets, retention, and version freeze operations.

Frontend visibility is not a security boundary; database/storage policies enforce authorization.

## 25. Audio storage and retention

Audio is stored in a private Supabase Storage bucket.

Suggested path structure:

`research/<study-id>/<student-id>/<attempt-id>.webm`

Requirements:

- no public bucket;
- no permanent public URL;
- short-lived signed URLs for authorized playback;
- ability to delete one participant's retained audio;
- ability to delete all audio for a study;
- metadata/scores may remain after audio deletion if study policy permits;
- deletion actions should be logged.

## 26. Offline behavior

Core analysis should continue without an active server connection once required local assets/models are available.

Offline sequence:

`record -> analyze -> score -> feedback -> store result/audio reference in IndexedDB -> mark pending-sync`

When connectivity returns:

`pending-sync -> upload audio -> sync structured result -> confirm synced`

UI states must clearly distinguish:

- analyzed locally;
- waiting to sync;
- syncing;
- synced;
- sync failed/retry needed.

## 27. PWA behavior

SpeakSense should be installable as a PWA where supported.

The service worker may cache:

- application shell;
- published content needed for assigned practice;
- model/runtime assets where feasible and license-compliant.

Sensitive research data should remain in controlled local storage and be synchronized according to the defined queue; the cache must not expose private recordings as public assets.

## 28. MVP scope before 05/10/2026

The competition MVP must provide real, testable functionality for:

1. Student/Teacher/Admin authentication.
2. Teacher class creation.
3. Class-code joining.
4. Mobile/laptop recording.
5. Word Lab.
6. Sentence Lab.
7. Passage Lab.
8. US/UK reference profiles.
9. Six component scores plus overall score.
10. Bilingual feedback.
11. Audio retention and playback controls.
12. Attempt history.
13. Pronunciation error map.
14. Basic deterministic adaptive practice.
15. Pre-test/Post-test mode.
16. Control/Experimental cohort management.
17. Teacher analytics.
18. Blind human validation.
19. Research dashboard.
20. De-identified CSV export.
21. Research version freeze.
22. Audio-retention deletion controls.
23. IndexedDB pending-sync queue.

## 29. Explicit non-goals for competition MVP

The following are deferred unless all research-critical features are stable:

- free-speaking scoring;
- general-purpose chatbot;
- LLM-generated lessons;
- social feed;
- public leaderboard;
- parent portal;
- complex badges/rewards;
- native iOS/Android apps;
- paid AI API integration.

## 30. Testing strategy

### 30.1 Unit tests

Cover at minimum:

- scoring calculations;
- score bounds;
- weight/version behavior;
- adaptive need ranking;
- error-family mapping;
- confidence rules;
- export anonymization;
- research freeze immutability.

### 30.2 Integration tests

Cover:

- authentication/role flow;
- class join flow;
- attempt persistence;
- audio upload permissions;
- signed playback permissions;
- human-review flow;
- research exports;
- offline queue recovery.

### 30.3 RLS/security tests

Verify that:

- Student A cannot read Student B data;
- one teacher cannot read another teacher's unrelated class;
- private audio cannot be fetched without authorization;
- a modified frontend cannot bypass database rules;
- control participants cannot enable experimental intervention during a frozen study.

### 30.4 Device tests

Representative testing should include:

- iPhone Safari;
- Android Chrome;
- desktop Chrome/Edge;
- macOS Safari where feasible.

Benchmark:

- first model load;
- cached startup;
- inference latency;
- memory use;
- battery/thermal behavior on mobile;
- recording compatibility.

### 30.5 Research reliability tests

Before the main post-test analysis:

- verify scoring-version consistency;
- verify content/reference versions;
- check missing data;
- inspect low-confidence samples;
- complete planned blind human-validation subset;
- document excluded attempts and reasons.

## 31. Error handling

SpeakSense should use explicit recoverable states instead of silent failure.

Examples:

- microphone denied -> permission guidance;
- unsupported recording codec -> fallback or clear unsupported message;
- model load failure -> retry/cache reset guidance;
- low-quality audio -> retry, no normal research score;
- local analysis succeeds but sync fails -> preserve local result and retry later;
- server upload succeeds but metadata write fails -> reconciliation job/state;
- frozen-study configuration mismatch -> block submission and report configuration error.

## 32. Research integrity safeguards

- Frozen scoring/test/reference versions cannot be silently edited.
- Pre-test/post-test activity is marked separately from normal practice.
- Human reviewers are blinded to automated scores until submission.
- Control-group intervention access is disabled during the study period.
- Excluded/failed recordings are logged with reasons.
- De-identified exports are the default for analysis.
- Algorithm changes create a new version.
- The application never claims 100% accuracy.

## 33. Product success criteria

The competition-ready product is considered successful when:

- students can record and receive browser-based pronunciation feedback on both phone and laptop without paid AI calls;
- teachers can run a two-group pre/post study;
- the experimental group receives adaptive practice while the control group does not;
- all research results can be traced to frozen scoring/content/reference versions;
- at least the planned human-validation subset can be blindly rated and compared;
- research data can be exported anonymously;
- role isolation and private audio access are enforced by RLS/storage policies;
- the core workflow remains usable during temporary network loss after assets are cached;
- enough reliable data is collected to analyze pronunciation change and automated-vs-human agreement.

## 34. Key implementation risks

### Browser model performance

Risk: candidate acoustic models may be too large or slow on phones.  
Mitigation: benchmark early, use quantization, lazy loading, WebGPU when available, and a lightweight fallback.

### Phoneme-level validity

Risk: browser acoustic output may not be accurate enough for fine-grained phoneme judgments.  
Mitigation: use controlled reading, confidence thresholds, human validation, and avoid overclaiming unsupported error labels.

### Cross-device score drift

Risk: microphones/devices may influence scores.  
Mitigation: normalize audio, collect device metadata, freeze scoring logic, test representative hardware, and analyze potential device effects.

### Offline storage loss

Risk: browser storage may be cleared before sync.  
Mitigation: clear pending-sync states, visible sync status, retry logic, and teacher monitoring of incomplete uploads.

### Research timeline

Risk: the 05/10/2026 deadline leaves little time for a three-week intervention.  
Mitigation: prioritize research-critical MVP, start model benchmarking and pre-test readiness immediately, defer non-goals, and continue longer-term follow-up after submission.

## 35. Implementation boundaries

Modules should be isolated behind stable interfaces:

- `AudioEngine`
- `AcousticModelAdapter`
- `AlignmentEngine`
- `ScoringEngine`
- `ErrorModel`
- `AdaptiveEngine`
- `ResearchService`
- `SyncQueue`
- `StorageService`

The UI consumes domain outputs and must not contain scoring mathematics or security decisions.

The database is the authorization boundary; the browser is the local-analysis boundary.

## 36. Definition of done for the first research-ready release

The release is ready to begin the Grade 11 study only after all of the following are true:

- production auth and RLS are verified;
- class join works end-to-end;
- US and UK references are versioned;
- scoring version is frozen;
- selected browser acoustic model has documented device benchmarks;
- Word/Sentence/Passage attempts produce stored results;
- pre-test mode prevents immediate corrective practice;
- control/experimental assignment is enforced;
- audio is private and authorized playback works;
- blind-review workflow works;
- CSV export is de-identified;
- pending-sync survives offline/reconnect tests;
- at least one pilot class has completed an end-to-end dry run;
- scoring limitations and research exclusions are documented.

## 37. Next step

After this specification is reviewed and accepted, create a detailed implementation plan. Implementation should proceed in small verifiable stages, with model feasibility and scoring validity tested early before investing heavily in visual polish.
