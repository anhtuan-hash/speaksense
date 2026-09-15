-- SpeakSense authorization boundary. Browser UI guards are UX only;
-- these policies are the source of truth for data access.

create or replace function public.current_app_role()
returns public.app_role
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select p.role
  from public.profiles p
  where p.id = auth.uid()
  limit 1;
$$;

create or replace function public.teacher_owns_class(p_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.classes c
    where c.id = p_class_id
      and c.teacher_id = auth.uid()
  );
$$;

create or replace function public.teacher_can_access_student(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.classes c
    join public.class_members cm on cm.class_id = c.id
    where c.teacher_id = auth.uid()
      and cm.student_id = p_student_id
  );
$$;

create or replace function public.student_is_class_member(p_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.class_members cm
    where cm.class_id = p_class_id
      and cm.student_id = auth.uid()
      and cm.status = 'active'
  );
$$;

create or replace function public.is_study_participant(p_study_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.study_participants sp
    where sp.study_id = p_study_id
      and sp.student_id = auth.uid()
      and sp.participation_status = 'active'
  );
$$;

create or replace function public.teacher_can_access_study(p_study_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.study_participants sp
    join public.class_members cm on cm.student_id = sp.student_id
    join public.classes c on c.id = cm.class_id
    where sp.study_id = p_study_id
      and c.teacher_id = auth.uid()
  );
$$;

create or replace function public.owns_attempt(p_attempt_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.attempts a
    where a.id = p_attempt_id
      and a.student_id = auth.uid()
  );
$$;

create or replace function public.can_access_attempt(p_attempt_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.attempts a
    where a.id = p_attempt_id
      and (
        a.student_id = auth.uid()
        or public.current_app_role() = 'admin'
        or (
          public.current_app_role() = 'teacher'
          and public.teacher_can_access_student(a.student_id)
        )
      )
  );
$$;

revoke all on function public.current_app_role() from public;
revoke all on function public.teacher_owns_class(uuid) from public;
revoke all on function public.teacher_can_access_student(uuid) from public;
revoke all on function public.student_is_class_member(uuid) from public;
revoke all on function public.is_study_participant(uuid) from public;
revoke all on function public.teacher_can_access_study(uuid) from public;
revoke all on function public.owns_attempt(uuid) from public;
revoke all on function public.can_access_attempt(uuid) from public;

grant execute on function public.current_app_role() to authenticated;
grant execute on function public.teacher_owns_class(uuid) to authenticated;
grant execute on function public.teacher_can_access_student(uuid) to authenticated;
grant execute on function public.student_is_class_member(uuid) to authenticated;
grant execute on function public.is_study_participant(uuid) to authenticated;
grant execute on function public.teacher_can_access_study(uuid) to authenticated;
grant execute on function public.owns_attempt(uuid) to authenticated;
grant execute on function public.can_access_attempt(uuid) to authenticated;

alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.class_members enable row level security;
alter table public.research_studies enable row level security;
alter table public.study_participants enable row level security;
alter table public.content_items enable row level security;
alter table public.pronunciation_references enable row level security;
alter table public.attempts enable row level security;
alter table public.attempt_scores enable row level security;
alter table public.pronunciation_errors enable row level security;
alter table public.human_reviews enable row level security;
alter table public.scoring_versions enable row level security;
alter table public.adaptive_versions enable row level security;
alter table public.consent_records enable row level security;
alter table public.audit_events enable row level security;

-- Explicit privileges make the policy behavior testable. Anonymous receives
-- SELECT only on the two research tables, where absence of anon policies yields
-- an empty result rather than relying on a permission error.
grant usage on schema public to anon, authenticated;
grant select on public.research_studies, public.study_participants to anon;
grant select, insert, update, delete on
  public.profiles,
  public.classes,
  public.class_members,
  public.research_studies,
  public.study_participants,
  public.content_items,
  public.pronunciation_references,
  public.attempts,
  public.attempt_scores,
  public.pronunciation_errors,
  public.human_reviews,
  public.scoring_versions,
  public.adaptive_versions,
  public.consent_records,
  public.audit_events
  to authenticated;

grant usage, select on sequence public.audit_events_id_seq to authenticated;

-- Profiles
create policy profiles_select_authorized
on public.profiles for select
to authenticated
using (
  id = auth.uid()
  or public.current_app_role() = 'admin'
  or (
    public.current_app_role() = 'teacher'
    and public.teacher_can_access_student(id)
  )
);

create policy profiles_update_admin
on public.profiles for update
to authenticated
using (public.current_app_role() = 'admin')
with check (public.current_app_role() = 'admin');

create policy profiles_delete_admin
on public.profiles for delete
to authenticated
using (public.current_app_role() = 'admin');

-- Classes
create policy classes_select_authorized
on public.classes for select
to authenticated
using (
  public.current_app_role() = 'admin'
  or teacher_id = auth.uid()
  or public.student_is_class_member(id)
);

create policy classes_insert_staff
on public.classes for insert
to authenticated
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'teacher' and teacher_id = auth.uid())
);

create policy classes_update_owner_or_admin
on public.classes for update
to authenticated
using (
  public.current_app_role() = 'admin'
  or teacher_id = auth.uid()
)
with check (
  public.current_app_role() = 'admin'
  or teacher_id = auth.uid()
);

create policy classes_delete_owner_or_admin
on public.classes for delete
to authenticated
using (
  public.current_app_role() = 'admin'
  or teacher_id = auth.uid()
);

-- Class membership. Students cannot directly add themselves; the secure join
-- RPC in a later migration is the only student-facing membership write path.
create policy class_members_select_authorized
on public.class_members for select
to authenticated
using (
  student_id = auth.uid()
  or public.current_app_role() = 'admin'
  or public.teacher_owns_class(class_id)
);

create policy class_members_insert_staff
on public.class_members for insert
to authenticated
with check (
  public.current_app_role() = 'admin'
  or public.teacher_owns_class(class_id)
);

create policy class_members_update_staff
on public.class_members for update
to authenticated
using (
  public.current_app_role() = 'admin'
  or public.teacher_owns_class(class_id)
)
with check (
  public.current_app_role() = 'admin'
  or public.teacher_owns_class(class_id)
);

create policy class_members_delete_staff
on public.class_members for delete
to authenticated
using (
  public.current_app_role() = 'admin'
  or public.teacher_owns_class(class_id)
);

-- Research studies and participant assignments
create policy research_studies_select_authorized
on public.research_studies for select
to authenticated
using (
  public.current_app_role() = 'admin'
  or public.is_study_participant(id)
  or (
    public.current_app_role() = 'teacher'
    and public.teacher_can_access_study(id)
  )
);

create policy research_studies_insert_admin
on public.research_studies for insert
to authenticated
with check (public.current_app_role() = 'admin');

create policy research_studies_update_admin
on public.research_studies for update
to authenticated
using (public.current_app_role() = 'admin')
with check (public.current_app_role() = 'admin');

create policy research_studies_delete_admin
on public.research_studies for delete
to authenticated
using (public.current_app_role() = 'admin');

create policy study_participants_select_authorized
on public.study_participants for select
to authenticated
using (
  student_id = auth.uid()
  or public.current_app_role() = 'admin'
  or (
    public.current_app_role() = 'teacher'
    and public.teacher_can_access_student(student_id)
  )
);

create policy study_participants_insert_admin
on public.study_participants for insert
to authenticated
with check (public.current_app_role() = 'admin');

create policy study_participants_update_admin
on public.study_participants for update
to authenticated
using (public.current_app_role() = 'admin')
with check (public.current_app_role() = 'admin');

create policy study_participants_delete_admin
on public.study_participants for delete
to authenticated
using (public.current_app_role() = 'admin');

-- Learning content: authenticated users can consume published content.
-- Teachers can manage only content they created; canonical references remain
-- admin-managed for research reproducibility.
create policy content_items_select_authorized
on public.content_items for select
to authenticated
using (
  publish_status = 'published'
  or public.current_app_role() = 'admin'
  or created_by = auth.uid()
);

create policy content_items_insert_staff
on public.content_items for insert
to authenticated
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'teacher' and created_by = auth.uid())
);

create policy content_items_update_staff
on public.content_items for update
to authenticated
using (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'teacher' and created_by = auth.uid())
)
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'teacher' and created_by = auth.uid())
);

create policy content_items_delete_staff
on public.content_items for delete
to authenticated
using (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'teacher' and created_by = auth.uid())
);

create policy pronunciation_references_select_authorized
on public.pronunciation_references for select
to authenticated
using (
  exists (
    select 1
    from public.content_items ci
    where ci.id = pronunciation_references.content_id
  )
);

create policy pronunciation_references_insert_admin
on public.pronunciation_references for insert
to authenticated
with check (public.current_app_role() = 'admin');

create policy pronunciation_references_update_admin
on public.pronunciation_references for update
to authenticated
using (public.current_app_role() = 'admin')
with check (public.current_app_role() = 'admin');

create policy pronunciation_references_delete_admin
on public.pronunciation_references for delete
to authenticated
using (public.current_app_role() = 'admin');

-- Attempts and machine-derived results
create policy attempts_select_authorized
on public.attempts for select
to authenticated
using (
  student_id = auth.uid()
  or public.current_app_role() = 'admin'
  or (
    public.current_app_role() = 'teacher'
    and public.teacher_can_access_student(student_id)
  )
);

create policy attempts_insert_owner_or_admin
on public.attempts for insert
to authenticated
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and student_id = auth.uid())
);

create policy attempts_update_owner_or_admin
on public.attempts for update
to authenticated
using (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and student_id = auth.uid())
)
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and student_id = auth.uid())
);

create policy attempts_delete_admin
on public.attempts for delete
to authenticated
using (public.current_app_role() = 'admin');

create policy attempt_scores_select_authorized
on public.attempt_scores for select
to authenticated
using (public.can_access_attempt(attempt_id));

create policy attempt_scores_insert_owner_or_admin
on public.attempt_scores for insert
to authenticated
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and public.owns_attempt(attempt_id))
);

create policy attempt_scores_update_owner_or_admin
on public.attempt_scores for update
to authenticated
using (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and public.owns_attempt(attempt_id))
)
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and public.owns_attempt(attempt_id))
);

create policy pronunciation_errors_select_authorized
on public.pronunciation_errors for select
to authenticated
using (public.can_access_attempt(attempt_id));

create policy pronunciation_errors_insert_owner_or_admin
on public.pronunciation_errors for insert
to authenticated
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and public.owns_attempt(attempt_id))
);

create policy pronunciation_errors_update_owner_or_admin
on public.pronunciation_errors for update
to authenticated
using (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and public.owns_attempt(attempt_id))
)
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and public.owns_attempt(attempt_id))
);

-- Human reviews are visible only to the submitting reviewer and admins.
create policy human_reviews_select_reviewer_or_admin
on public.human_reviews for select
to authenticated
using (
  public.current_app_role() = 'admin'
  or reviewer_id = auth.uid()
);

create policy human_reviews_insert_teacher_or_admin
on public.human_reviews for insert
to authenticated
with check (
  public.current_app_role() = 'admin'
  or (
    public.current_app_role() = 'teacher'
    and reviewer_id = auth.uid()
    and public.can_access_attempt(attempt_id)
  )
);

create policy human_reviews_update_reviewer_or_admin
on public.human_reviews for update
to authenticated
using (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'teacher' and reviewer_id = auth.uid())
)
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'teacher' and reviewer_id = auth.uid())
);

-- Version definitions are readable by authenticated users so each stored score
-- can be interpreted, but only admins can mutate them.
create policy scoring_versions_select_authenticated
on public.scoring_versions for select
to authenticated
using (auth.uid() is not null);

create policy scoring_versions_write_admin
on public.scoring_versions for all
to authenticated
using (public.current_app_role() = 'admin')
with check (public.current_app_role() = 'admin');

create policy adaptive_versions_select_authenticated
on public.adaptive_versions for select
to authenticated
using (auth.uid() is not null);

create policy adaptive_versions_write_admin
on public.adaptive_versions for all
to authenticated
using (public.current_app_role() = 'admin')
with check (public.current_app_role() = 'admin');

-- Consent belongs to the student. Teachers may read consent state for students
-- they legitimately teach but cannot modify it.
create policy consent_records_select_authorized
on public.consent_records for select
to authenticated
using (
  student_id = auth.uid()
  or public.current_app_role() = 'admin'
  or (
    public.current_app_role() = 'teacher'
    and public.teacher_can_access_student(student_id)
  )
);

create policy consent_records_insert_owner_or_admin
on public.consent_records for insert
to authenticated
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and student_id = auth.uid())
);

create policy consent_records_update_owner_or_admin
on public.consent_records for update
to authenticated
using (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and student_id = auth.uid())
)
with check (
  public.current_app_role() = 'admin'
  or (public.current_app_role() = 'student' and student_id = auth.uid())
);

-- Audit records are append-only through trusted SECURITY DEFINER workflows.
-- Direct authenticated writes intentionally have no policy.
create policy audit_events_select_admin
on public.audit_events for select
to authenticated
using (public.current_app_role() = 'admin');
