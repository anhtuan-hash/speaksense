# SpeakSense Content Bank, PWA, System Health, and Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the remaining product obligations from the approved spec: teacher/admin content publishing, installable PWA behavior, offline-safe app/content caching, system-health visibility, and a reproducible research release process.

**Architecture:** Content is authored as versioned controlled-reading items with paired US/UK references and published through authorization-checked services. The PWA caches only public application/runtime/content assets; private recordings/research data remain in IndexedDB/Supabase paths controlled by the existing sync/storage layer. Release health reports verify app, database, storage, model, and research-version readiness.

**Tech Stack:** React, TypeScript, Supabase, Vite, `vite-plugin-pwa`, Workbox, Zod, Vitest, Playwright.

**Spec:** `docs/superpowers/specs/2026-09-15-speaksense-design.md`

## Global Constraints

- Content is controlled reading only: word, sentence, passage.
- Every research-capable content item has versioned US and UK references.
- Passage MVP length is 40–80 words.
- Teacher content permissions remain class-scoped; canonical research/test/reference publication is Admin-controlled.
- PWA caches must never expose private recordings as public cache entries.
- Model assets may use the model library/browser cache; do not duplicate large cross-origin model artifacts in Workbox unless tested and license/CORS behavior is confirmed.
- Research release must record exact app/scoring/adaptive/test/reference versions.

---

### Task 1: Implement versioned Content Bank service

**Files:**
- Create: `src/content/contentService.ts`
- Create: `src/content/contentSchema.ts`
- Create: `tests/unit/content/contentService.test.ts`
- Create: `supabase/migrations/010_content_publication.sql`

**Interfaces:**
- Produces create/edit/draft/archive operations for teacher-owned drafts and admin publication/versioning for canonical items.

- [ ] **Step 1: Write schema/service tests**

Validate type, grade metadata, target tags, passage 40–80 word limit, paired US/UK reference presence for published research content, and immutable published version IDs.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement draft/publish lifecycle**

A published/version-referenced item is immutable; edits create a new content version. Teachers can manage their own drafts; Admin publishes canonical research/test/reference versions.

- [ ] **Step 4: Run tests and SQL policy tests**
- [ ] **Step 5: Commit**

```bash
git add src/content supabase/migrations/010_content_publication.sql tests/unit/content
git commit -m "feat: add versioned pronunciation content bank"
```

### Task 2: Build Teacher Content Bank and Admin publishing UI

**Files:**
- Create: `src/pages/teacher/ContentBankPage.tsx`
- Create: `src/pages/admin/ContentPublishingPage.tsx`
- Create: `src/components/content/ContentEditor.tsx`
- Modify: `src/app/routes.tsx`
- Create: `tests/e2e/content-bank.spec.ts`

**Interfaces:**
- Consumes content service/reference validation.
- Produces teacher route `/teacher/content` and admin route `/admin/content`.

- [ ] **Step 1: Write E2E tests for draft creation, teacher isolation, Admin publish, and immutable published item**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement editor with explicit US/UK reference validation feedback**
- [ ] **Step 4: Run tests/build**
- [ ] **Step 5: Commit**

### Task 3: Make SpeakSense installable as a PWA

**Files:**
- Modify: `vite.config.ts`
- Create: `public/icons/README.md`
- Create: `src/pwa/registerPwa.ts`
- Create: `tests/unit/pwa/pwaConfig.test.ts`

**Interfaces:**
- Produces web app manifest, service worker registration, app-shell caching, offline navigation fallback.

- [ ] **Step 1: Write configuration test**

Assert manifest includes name `SpeakSense`, standalone display, start URL, theme/background metadata, and icons supplied by the project (do not bundle copyrighted third-party icons without permission).

- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Configure `vite-plugin-pwa`**

Precache hashed application shell assets. Runtime-cache published non-sensitive content/reference JSON with stale-while-revalidate or network-first according to update semantics. Explicitly exclude `/research-audio/`, signed audio URLs, Auth tokens, and private API responses from public Workbox caches.

- [ ] **Step 4: Build and inspect generated manifest/service worker**
- [ ] **Step 5: Commit**

### Task 4: Add offline readiness indicator

**Files:**
- Create: `src/pwa/offlineReadiness.ts`
- Create: `src/components/system/OfflineReadinessCard.tsx`
- Create: `tests/unit/pwa/offlineReadiness.test.ts`

**Interfaces:**
- Produces readiness state `{ appShell, contentPack, modelCache, pendingSyncCount }`.

- [ ] **Step 1: Write tests for ready/partial/not-ready states**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement checks without reading private audio into Cache API**

Model-cache readiness is reported through the selected model adapter/cache metadata rather than assuming Workbox owns model assets.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 5: Implement Admin System Health page

**Files:**
- Create: `src/admin/healthService.ts`
- Create: `src/pages/admin/SystemHealthPage.tsx`
- Create: `tests/unit/system/healthService.test.ts`

**Interfaces:**
- Produces checks for browser app version, Supabase connectivity, storage access, model selection/version, current research freeze completeness, pending sync/error counts, and last successful release gate.

- [ ] **Step 1: Write tests with healthy/degraded fixtures**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement health checks with non-secret public metadata only**

Never render service-role keys, access tokens, signed URLs, raw private storage paths, or student-identifying research data on the health page.

- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 6: Add release metadata and reproducibility manifest

**Files:**
- Create: `src/release/releaseManifest.ts`
- Create: `scripts/write-release-manifest.mjs`
- Create: `public/release.json`
- Create: `tests/unit/release/releaseManifest.test.ts`

**Interfaces:**
- Produces public non-sensitive release manifest containing app commit/version, build timestamp, selected acoustic model id, and supported runtime metadata. Research snapshots separately store their scoring/adaptive/test/reference versions.

- [ ] **Step 1: Write manifest schema tests**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Generate manifest during production build from environment/commit metadata**
- [ ] **Step 4: Run build twice and verify deterministic schema with changed build timestamp/commit as expected**
- [ ] **Step 5: Commit**

### Task 7: Add PWA/offline E2E release verification

**Files:**
- Create: `tests/e2e/pwa-offline.spec.ts`
- Create: `docs/release/research-ready-checklist.md`

**Interfaces:**
- Verifies installed-app/offline behavior with cached shell/content plus existing IndexedDB pending-sync flow.

- [ ] **Step 1: Write Playwright offline test**

Online first load -> cache shell/content -> go offline -> navigate to cached student page -> open assigned cached content -> verify model readiness behavior -> create local attempt through mocked scoring -> see pending sync -> reconnect -> sync.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Fix only release-blocking cache/routing issues exposed by test**
- [ ] **Step 4: Run `npm test && npm run build && npm run test:e2e`**
- [ ] **Step 5: Commit checklist and evidence**

## Content/PWA/release exit criteria

Teachers can manage authorized content drafts, Admin can publish immutable research-ready content/reference versions, SpeakSense is installable and retains its non-sensitive app/content shell offline, private audio never enters public PWA caches, Admin can inspect health without secret leakage, and each release has reproducible version metadata suitable for the research log.