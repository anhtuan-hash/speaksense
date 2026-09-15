# SpeakSense Account Provisioning and Research Consent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete secure account onboarding that the foundation plan intentionally leaves open: self-service student registration through a valid class code, Admin-managed teacher provisioning, and versioned research/audio consent before research data is retained.

**Architecture:** Public browser clients never receive the Supabase service-role key. Account creation that needs privileged Auth Admin APIs runs in Supabase Edge Functions after database-backed authorization/class-code validation. Student credentials remain username/password externally and synthetic email internally.

**Tech Stack:** Supabase Auth, Supabase Edge Functions (Deno/TypeScript), PostgreSQL RPC/RLS, React/TypeScript, Vitest, SQL tests.

**Spec:** `docs/superpowers/specs/2026-09-15-speaksense-design.md`

## Global Constraints

- Students do not need personal email addresses.
- Do not build custom password hashing.
- Teacher/Admin login remains email/password.
- Service-role credentials may exist only in server-side Supabase secrets/Edge Functions.
- Student registration requires a valid active class code.
- Research/audio retention must respect a versioned consent record.

---

### Task 1: Implement atomic student registration Edge Function

**Files:**
- Create: `supabase/functions/register-student/index.ts`
- Create: `supabase/functions/_shared/validation.ts`
- Create: `supabase/migrations/004b_student_registration.sql`
- Create: `tests/functions/register-student.test.ts`

**Interfaces:**
- Produces POST body `{ username, password, displayName, classCode }` and success `{ userId, classId }`.

- [ ] **Step 1: Write tests for invalid class code, duplicate username, weak password, disabled class, and successful registration**
- [ ] **Step 2: Run tests and verify failure**
- [ ] **Step 3: Implement function**

Normalize username using the same rule as `studentEmailForUsername()`. Hash/lookup class code through database helper, create Auth user using server-side `auth.admin.createUser({ email: syntheticEmail, password, email_confirm: true })`, then create `profiles` + `class_members`. If database membership creation fails after Auth user creation, delete the newly created Auth user before returning failure.

- [ ] **Step 4: Run function/SQL tests**
- [ ] **Step 5: Commit**

```bash
git add supabase/functions supabase/migrations/004b_student_registration.sql tests/functions/register-student.test.ts
git commit -m "feat: add secure student self-registration"
```

### Task 2: Add student registration UI and auth service method

**Files:**
- Modify: `src/auth/authService.ts`
- Create: `src/pages/StudentRegisterPage.tsx`
- Modify: `src/app/routes.tsx`
- Create: `tests/unit/studentRegister.test.tsx`

**Interfaces:**
- Produces `registerStudent(input: { username; password; displayName; classCode }): Promise<void>`.

- [ ] **Step 1: Write UI/service tests**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement registration form with explicit class-code and validation errors**
- [ ] **Step 4: Run tests/build**
- [ ] **Step 5: Commit**

### Task 3: Implement Admin teacher provisioning

**Files:**
- Create: `supabase/functions/provision-teacher/index.ts`
- Create: `src/admin/teacherService.ts`
- Create: `src/pages/admin/TeacherAccountsPage.tsx`
- Create: `tests/functions/provision-teacher.test.ts`

**Interfaces:**
- Produces admin-only create/disable teacher account operations.

- [ ] **Step 1: Write tests proving non-admin callers are rejected before Auth Admin actions**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement function authorization using caller JWT -> `profiles.role='admin'` check, then Auth Admin create/update**
- [ ] **Step 4: Run tests**
- [ ] **Step 5: Commit**

### Task 4: Implement versioned research/audio consent

**Files:**
- Create: `src/research/consentService.ts`
- Create: `src/pages/student/ResearchConsentPage.tsx`
- Create: `supabase/migrations/004c_consent.sql`
- Create: `tests/unit/consentService.test.ts`
- Create: `tests/sql/004c_consent.sql`

**Interfaces:**
- Produces:

```ts
export type ConsentDecision = {
  studyId: string;
  consentVersion: string;
  participate: boolean;
  retainAudio: boolean;
  decidedAt: string;
};
export function canRetainResearchAudio(consent: ConsentDecision | null): boolean;
```

- [ ] **Step 1: Write tests for no-consent, participate-without-audio, and participate-with-audio states**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement append-only consent records and student consent page**

Changing a decision creates a new consent event/versioned row; do not overwrite historical consent. Study participation/test start must be blocked until the required current consent version is recorded. Audio upload path must check `retainAudio=true` for research recordings.

- [ ] **Step 4: Run unit/SQL tests**
- [ ] **Step 5: Commit**

### Task 5: Verify onboarding end-to-end

**Files:**
- Create: `tests/e2e/onboarding-consent.spec.ts`

**Interfaces:**
- Validates teacher class creation -> student self-registration by class code -> login -> research consent -> eligible study status.

- [ ] **Step 1: Write E2E flow and negative cases**
- [ ] **Step 2: Run and verify failure before wiring is complete**
- [ ] **Step 3: Wire routes/services**
- [ ] **Step 4: Run `npm test && npm run test:e2e -- onboarding-consent.spec.ts && npm run build`**
- [ ] **Step 5: Commit**

## Provisioning/consent exit criteria

Students can create their own username/password account only with a valid active class code, Admin can provision teacher accounts without exposing service-role credentials to the browser, and research/audio data retention is gated by an auditable versioned consent decision.