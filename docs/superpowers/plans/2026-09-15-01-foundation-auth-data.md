# SpeakSense Foundation, Auth, and Research Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a deployable React/TypeScript PWA foundation with Supabase authentication, role isolation, classes/class codes, research-study records, immutable research snapshots, and RLS-backed authorization.

**Architecture:** Use Vite + React + TypeScript for the standalone web app and Supabase for Auth/PostgreSQL. The browser owns presentation and later local analysis; PostgreSQL RLS is the authorization boundary. This plan deliberately stops before microphone/model work so the result is independently testable as a secure multi-role research shell.

**Tech Stack:** Vite, React, TypeScript, React Router, `@supabase/supabase-js`, Zod, Vitest, Testing Library, Playwright, Supabase SQL migrations.

**Spec:** `docs/superpowers/specs/2026-09-15-speaksense-design.md`

## Global Constraints

- AI operating cost must be 0 VND.
- Product is a standalone browser-first web/PWA.
- Student roles use username/password; Teacher/Admin use email/password.
- Do not implement custom password hashing.
- RLS is mandatory and is the final authorization boundary.
- Research records must be traceable to versioned/frozen configuration.
- Primary research population is Grade 11; Grades 10/12 remain usable outside the principal study.
- The first research-ready MVP must be operational before 05/10/2026.

---

## File map

- `package.json` — scripts and dependencies.
- `vite.config.ts` — Vite/Vitest configuration.
- `src/main.tsx` — app bootstrap.
- `src/app/App.tsx` — routes and role-aware shell.
- `src/app/routes.tsx` — route definitions.
- `src/lib/env.ts` — validated environment variables.
- `src/lib/supabase.ts` — singleton Supabase client.
- `src/auth/authService.ts` — teacher/admin and synthetic-email student auth functions.
- `src/auth/AuthProvider.tsx` — session/profile state.
- `src/auth/RequireRole.tsx` — client navigation guard only; never replaces RLS.
- `src/classes/classService.ts` — create class, rotate code, join class.
- `src/research/researchService.ts` — study creation, participant assignment, freeze.
- `src/pages/*` — minimal dashboards for each role.
- `supabase/migrations/001_core.sql` — tables, enums, triggers.
- `supabase/migrations/002_rls.sql` — policies and helper functions.
- `supabase/migrations/003_research_freeze.sql` — immutable snapshot/freeze functions.
- `tests/unit/*` — service/unit tests.
- `tests/e2e/*` — role and join flows.

### Task 1: Scaffold the app and test harness

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `vite.config.ts`
- Create: `index.html`
- Create: `src/main.tsx`
- Create: `src/app/App.tsx`
- Create: `src/app/routes.tsx`
- Create: `src/styles/global.css`
- Create: `tests/unit/app-smoke.test.tsx`

**Interfaces:**
- Produces: React app mount at `#root`; `App(): JSX.Element`.

- [ ] **Step 1: Write the failing smoke test**

```tsx
import { render, screen } from '@testing-library/react';
import { App } from '../../src/app/App';

test('renders SpeakSense shell', () => {
  render(<App />);
  expect(screen.getByText(/SpeakSense/i)).toBeInTheDocument();
});
```

- [ ] **Step 2: Run the test and verify failure**

Run: `npm test -- app-smoke.test.tsx`
Expected: FAIL because project/app files do not exist.

- [ ] **Step 3: Add the minimal React/Vite project**

Use scripts:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:e2e": "playwright test"
  }
}
```

`src/app/App.tsx` initially returns a semantic shell containing the product name and a `<main>` outlet placeholder.

- [ ] **Step 4: Run tests and production build**

Run: `npm test && npm run build`
Expected: PASS and Vite production bundle completes.

- [ ] **Step 5: Commit**

```bash
git add package.json tsconfig.json vite.config.ts index.html src tests/unit/app-smoke.test.tsx
git commit -m "feat: scaffold SpeakSense web app"
```

### Task 2: Add validated environment and Supabase client

**Files:**
- Create: `.env.example`
- Create: `src/lib/env.ts`
- Create: `src/lib/supabase.ts`
- Create: `tests/unit/env.test.ts`

**Interfaces:**
- Produces: `env: { supabaseUrl: string; supabaseAnonKey: string }` and `supabase` client.

- [ ] **Step 1: Write failing env validation tests**

```ts
import { parsePublicEnv } from '../../src/lib/env';

test('rejects missing Supabase values', () => {
  expect(() => parsePublicEnv({})).toThrow(/VITE_SUPABASE_URL/);
});

test('accepts valid public configuration', () => {
  expect(parsePublicEnv({
    VITE_SUPABASE_URL: 'https://example.supabase.co',
    VITE_SUPABASE_ANON_KEY: 'anon-key'
  })).toEqual({
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'anon-key'
  });
});
```

- [ ] **Step 2: Run the tests and verify failure**

Run: `npm test -- env.test.ts`
Expected: FAIL because `parsePublicEnv` does not exist.

- [ ] **Step 3: Implement Zod validation and client**

`parsePublicEnv()` must read only public anon credentials. Never place a Supabase service-role key in browser code.

- [ ] **Step 4: Run test/build**

Run: `npm test -- env.test.ts && npm run build`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add .env.example src/lib tests/unit/env.test.ts
git commit -m "feat: configure Supabase client"
```

### Task 3: Create the core PostgreSQL schema

**Files:**
- Create: `supabase/migrations/001_core.sql`
- Create: `tests/sql/001_core_schema.sql`

**Interfaces:**
- Produces tables: `profiles`, `classes`, `class_members`, `research_studies`, `study_participants`, `content_items`, `pronunciation_references`, `attempts`, `attempt_scores`, `pronunciation_errors`, `human_reviews`, `scoring_versions`, `adaptive_versions`, `consent_records`, `audit_events`.

- [ ] **Step 1: Write schema assertions first**

`tests/sql/001_core_schema.sql` should assert required tables and enum/check values exist using `information_schema` and `pg_catalog`; raise exceptions on missing objects.

Example assertion:

```sql
do $$
begin
  if to_regclass('public.profiles') is null then
    raise exception 'profiles table missing';
  end if;
end $$;
```

- [ ] **Step 2: Run assertions against a clean local Supabase database**

Run: `supabase db reset && psql "$LOCAL_DB_URL" -f tests/sql/001_core_schema.sql`
Expected: FAIL before migration objects are added.

- [ ] **Step 3: Implement the schema**

Important columns and constraints:

```sql
create type public.app_role as enum ('student','teacher','admin');
create type public.study_cohort as enum ('control','experimental');
create type public.accent_profile as enum ('us','uk');
create type public.content_type as enum ('word','sentence','passage');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.app_role not null,
  display_name text not null,
  username text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint student_username_required check (role <> 'student' or username is not null)
);
```

`research_studies` must store status (`draft`, `frozen`, `active`, `completed`, `archived`) and immutable snapshot references after freeze. `study_participants` must unique `(study_id, student_id)` and `(study_id, participant_code)`.

- [ ] **Step 4: Reset DB and run schema assertions**

Run: `supabase db reset && psql "$LOCAL_DB_URL" -f tests/sql/001_core_schema.sql`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/001_core.sql tests/sql/001_core_schema.sql
git commit -m "feat: add SpeakSense research schema"
```

### Task 4: Implement RLS and role isolation

**Files:**
- Create: `supabase/migrations/002_rls.sql`
- Create: `tests/sql/002_rls_security.sql`

**Interfaces:**
- Produces SQL helpers `current_app_role()`, `teacher_owns_class(uuid)`, `teacher_can_access_student(uuid)` and RLS policies for core tables.

- [ ] **Step 1: Write security tests that impersonate users**

Cover at least:

```sql
-- Student A can read own profile.
-- Student A cannot read Student B attempts.
-- Teacher A can read students in Teacher A classes.
-- Teacher A cannot read Teacher B unrelated class.
-- Anonymous role cannot read research rows.
```

Use `set local role authenticated;` and JWT claim injection supported by local Supabase/Postgres tests.

- [ ] **Step 2: Run the security tests**

Run: `psql "$LOCAL_DB_URL" -f tests/sql/002_rls_security.sql`
Expected: FAIL because policies are absent.

- [ ] **Step 3: Add RLS policies**

Every user-owned/research table must `enable row level security`. Policies must derive access from `auth.uid()` and database membership, never from client-provided role strings.

- [ ] **Step 4: Run the security suite**

Run: `psql "$LOCAL_DB_URL" -f tests/sql/002_rls_security.sql`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/002_rls.sql tests/sql/002_rls_security.sql
git commit -m "feat: enforce role isolation with RLS"
```

### Task 5: Implement teacher/admin and student authentication

**Files:**
- Create: `src/auth/authService.ts`
- Create: `src/auth/AuthProvider.tsx`
- Create: `src/auth/RequireRole.tsx`
- Create: `src/pages/LoginPage.tsx`
- Create: `tests/unit/authService.test.ts`

**Interfaces:**
- Produces:
  - `studentEmailForUsername(username: string): string`
  - `signInStudent(username: string, password: string): Promise<AuthResult>`
  - `signInStaff(email: string, password: string): Promise<AuthResult>`
  - `signOut(): Promise<void>`
  - `useAuth(): { session; profile; loading }`

- [ ] **Step 1: Write synthetic-email normalization tests**

```ts
expect(studentEmailForUsername(' 11A1_TuanAnh '))
  .toBe('11a1_tuananh@students.speaksense.local');
expect(() => studentEmailForUsername('bad name!')).toThrow();
```

- [ ] **Step 2: Verify failure**

Run: `npm test -- authService.test.ts`
Expected: FAIL.

- [ ] **Step 3: Implement auth service/provider**

Normalize usernames to lowercase `[a-z0-9._-]`, 3–40 chars. Staff sign-in must never route through the synthetic namespace.

- [ ] **Step 4: Add role-routing tests and run suite**

Authenticated `student` -> `/student`; `teacher` -> `/teacher`; `admin` -> `/admin`; missing profile -> safe error/sign-out state.

Run: `npm test -- authService.test.ts && npm run build`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/auth src/pages/LoginPage.tsx tests/unit/authService.test.ts
git commit -m "feat: add role-aware authentication"
```

### Task 6: Implement classes, rotating join codes, and student join

**Files:**
- Create: `src/classes/classService.ts`
- Create: `src/pages/teacher/ClassesPage.tsx`
- Create: `src/pages/student/JoinClassPage.tsx`
- Create: `supabase/migrations/004_class_join_rpc.sql`
- Create: `tests/unit/classService.test.ts`
- Create: `tests/sql/004_class_join_rpc.sql`

**Interfaces:**
- Produces:
  - `createClass(input: { name: string; grade: 10|11|12 }): Promise<ClassRecord>`
  - `rotateJoinCode(classId: string): Promise<{ joinCode: string }>`
  - `joinClass(joinCode: string): Promise<ClassMembership>`
  - SQL RPC `join_class_by_code(p_code text)`.

- [ ] **Step 1: Write tests for invalid/rotated codes**

Test valid join, disabled code, rotated-old-code rejection, duplicate membership idempotency, and cross-teacher isolation.

- [ ] **Step 2: Run tests and verify failure**

Run: `npm test -- classService.test.ts`
Expected: FAIL.

- [ ] **Step 3: Implement secure join-code hashing and RPC**

Store only a hash of normalized uppercase join code in `classes`. Return plaintext only when created/rotated. `join_class_by_code` must obtain `auth.uid()` internally and only allow student profiles.

- [ ] **Step 4: Run SQL/unit/e2e class flow**

Run: `npm test -- classService.test.ts && psql "$LOCAL_DB_URL" -f tests/sql/004_class_join_rpc.sql`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/classes src/pages/teacher/ClassesPage.tsx src/pages/student/JoinClassPage.tsx supabase/migrations/004_class_join_rpc.sql tests
git commit -m "feat: add secure class-code joining"
```

### Task 7: Implement research studies, cohorts, accent lock, and immutable freeze

**Files:**
- Create: `src/research/researchService.ts`
- Create: `src/pages/admin/ResearchAdminPage.tsx`
- Create: `supabase/migrations/003_research_freeze.sql`
- Create: `tests/unit/researchService.test.ts`
- Create: `tests/sql/003_research_freeze.sql`

**Interfaces:**
- Produces:
  - `createStudy(input): Promise<ResearchStudy>`
  - `assignParticipant(input: { studyId; studentId; cohort; accent; participantCode }): Promise<void>`
  - `freezeStudy(studyId: string): Promise<ResearchSnapshot>`
  - SQL RPC `freeze_research_study(p_study_id uuid)`.

- [ ] **Step 1: Write freeze invariants**

Tests must prove:
- study freezes only with scoring/adaptive/test/reference versions present;
- duplicate participant codes fail;
- accent cannot change after freeze;
- cohort cannot change after freeze;
- snapshot fields cannot be updated after freeze.

- [ ] **Step 2: Run tests and verify failure**

Run: `psql "$LOCAL_DB_URL" -f tests/sql/003_research_freeze.sql`
Expected: FAIL.

- [ ] **Step 3: Implement atomic freeze RPC**

Within one transaction, lock the study row, validate required references, create immutable JSON snapshot, mark status `frozen`, and write `audit_events` entry.

- [ ] **Step 4: Run unit/SQL tests**

Run: `npm test -- researchService.test.ts && psql "$LOCAL_DB_URL" -f tests/sql/003_research_freeze.sql`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/research src/pages/admin/ResearchAdminPage.tsx supabase/migrations/003_research_freeze.sql tests
git commit -m "feat: freeze reproducible research studies"
```

### Task 8: Add minimal role dashboards and end-to-end foundation verification

**Files:**
- Create: `src/pages/student/StudentDashboard.tsx`
- Create: `src/pages/teacher/TeacherDashboard.tsx`
- Create: `src/pages/admin/AdminDashboard.tsx`
- Modify: `src/app/App.tsx`
- Modify: `src/app/routes.tsx`
- Create: `tests/e2e/auth-and-class.spec.ts`

**Interfaces:**
- Consumes auth/class/research services from earlier tasks.
- Produces stable route roots `/student`, `/teacher`, `/admin` for later plans.

- [ ] **Step 1: Write Playwright flow**

Flow: teacher sign-in -> create Grade 11 class -> obtain code -> student sign-in -> join -> student sees class -> unrelated teacher cannot access it.

- [ ] **Step 2: Run E2E and verify failure**

Run: `npm run test:e2e -- auth-and-class.spec.ts`
Expected: FAIL before pages/routes are wired.

- [ ] **Step 3: Wire role dashboards and route guards**

Use accessible navigation and explicit loading/error states. Client guards redirect for UX only; do not rely on them for authorization.

- [ ] **Step 4: Run all foundation checks**

Run: `npm test && npm run build && npm run test:e2e -- auth-and-class.spec.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/app src/pages tests/e2e/auth-and-class.spec.ts
git commit -m "feat: complete secure SpeakSense foundation"
```

## Foundation exit criteria

This plan is complete only when a local/preview deployment supports staff/student login, Grade 11 class creation/join, database-enforced role isolation, participant/cohort/accent assignment, and immutable research freeze. No audio or pronunciation score is required yet; those are implemented in subsequent plans.