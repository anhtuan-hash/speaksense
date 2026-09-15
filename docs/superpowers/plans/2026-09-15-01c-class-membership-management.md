# SpeakSense Class Membership Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the teacher class-management contract by allowing an authorized teacher to view, suspend, restore, or remove membership for students in their own class without deleting the student's account or research history.

**Architecture:** Membership status is the mutable relationship; student Auth/profile identity remains intact. RLS/RPC ownership checks enforce that only the class owner/authorized teacher can change membership. Historical attempts/research rows are never cascade-deleted by ordinary class membership changes.

**Tech Stack:** React, TypeScript, Supabase/PostgreSQL, Vitest, SQL tests.

**Spec:** `docs/superpowers/specs/2026-09-15-speaksense-design.md`

## Global Constraints

- Teacher access is limited to classes they own/manage.
- Removing a student from a class must not delete the student's account, attempts, scores, recordings, or research rows.
- Membership changes are auditable.
- A suspended/removed membership cannot use that class's current assignments or teacher-scoped data access.

---

### Task 1: Add membership status and teacher-owned management RPC

**Files:**
- Create: `supabase/migrations/004d_class_membership_management.sql`
- Create: `tests/sql/004d_class_membership_management.sql`

**Interfaces:**
- Produces RPC `set_class_membership_status(p_class_id uuid, p_student_id uuid, p_status text)` with statuses `active`, `suspended`, `removed`.

- [ ] **Step 1: Write SQL tests**

Verify owner teacher can suspend/restore/remove; unrelated teacher is rejected; student cannot modify membership; attempts remain after removal; each change writes `audit_events`.

- [ ] **Step 2: Run and verify failure**
- [ ] **Step 3: Implement RPC and RLS-aware status checks**
- [ ] **Step 4: Run SQL tests**
- [ ] **Step 5: Commit**

### Task 2: Add teacher membership management UI

**Files:**
- Modify: `src/classes/classService.ts`
- Create: `src/components/classes/ClassMemberList.tsx`
- Modify: `src/pages/teacher/ClassesPage.tsx`
- Create: `tests/unit/classes/ClassMemberList.test.tsx`

**Interfaces:**
- Produces `setMembershipStatus(classId, studentId, status)` and a member list with explicit status/actions.

- [ ] **Step 1: Write UI/service tests for active, suspended, removed and authorization errors**
- [ ] **Step 2: Verify failure**
- [ ] **Step 3: Implement management UI with confirmation for removal**
- [ ] **Step 4: Run tests/build**
- [ ] **Step 5: Commit**

### Task 3: Verify access after suspension/removal

**Files:**
- Create: `tests/e2e/class-membership.spec.ts`

**Interfaces:**
- Validates teacher suspend -> student loses class access; restore -> access returns; remove -> historical records remain visible to authorized research context but student no longer receives class assignments.

- [ ] **Step 1: Write E2E scenario**
- [ ] **Step 2: Run and verify failure before full wiring**
- [ ] **Step 3: Wire membership checks into class-scoped loaders**
- [ ] **Step 4: Run `npm test && npm run test:e2e -- class-membership.spec.ts && npm run build`**
- [ ] **Step 5: Commit**

## Membership exit criteria

Teachers can safely manage current class membership without destructive deletion, unauthorized users cannot alter another class, and research/history integrity survives membership changes.