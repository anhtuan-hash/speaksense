\set ON_ERROR_STOP on

begin;

-- Contract first: these helpers and RLS policies must exist before fixtures matter.
do $$
declare
  table_name text;
  secured_tables text[] := array[
    'profiles','classes','class_members','research_studies','study_participants',
    'content_items','pronunciation_references','attempts','attempt_scores',
    'pronunciation_errors','human_reviews','scoring_versions','adaptive_versions',
    'consent_records','audit_events'
  ];
begin
  if to_regprocedure('public.current_app_role()') is null then
    raise exception 'current_app_role() helper missing';
  end if;
  if to_regprocedure('public.teacher_owns_class(uuid)') is null then
    raise exception 'teacher_owns_class(uuid) helper missing';
  end if;
  if to_regprocedure('public.teacher_can_access_student(uuid)') is null then
    raise exception 'teacher_can_access_student(uuid) helper missing';
  end if;

  foreach table_name in array secured_tables loop
    if not coalesce((
      select c.relrowsecurity
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relname = table_name
    ), false) then
      raise exception 'RLS not enabled on %', table_name;
    end if;
  end loop;
end $$;

-- Fixed principals used to prove cross-user and cross-teacher isolation.
insert into auth.users (
  id, aud, role, email, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000101', 'authenticated', 'authenticated', 'student-a@example.test', '', '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('00000000-0000-0000-0000-000000000102', 'authenticated', 'authenticated', 'student-b@example.test', '', '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('00000000-0000-0000-0000-000000000201', 'authenticated', 'authenticated', 'teacher-a@example.test', '', '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('00000000-0000-0000-0000-000000000202', 'authenticated', 'authenticated', 'teacher-b@example.test', '', '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('00000000-0000-0000-0000-000000000301', 'authenticated', 'authenticated', 'admin@example.test', '', '{"provider":"email","providers":["email"]}', '{}', now(), now());

insert into public.profiles (id, role, display_name, username) values
  ('00000000-0000-0000-0000-000000000101', 'student', 'Student A', 'student.a'),
  ('00000000-0000-0000-0000-000000000102', 'student', 'Student B', 'student.b'),
  ('00000000-0000-0000-0000-000000000201', 'teacher', 'Teacher A', null),
  ('00000000-0000-0000-0000-000000000202', 'teacher', 'Teacher B', null),
  ('00000000-0000-0000-0000-000000000301', 'admin', 'Admin', null);

insert into public.classes (id, teacher_id, name, grade) values
  ('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000201', '11A Control', 11),
  ('00000000-0000-0000-0000-000000000402', '00000000-0000-0000-0000-000000000202', '11B Experimental', 11);

insert into public.class_members (class_id, student_id) values
  ('00000000-0000-0000-0000-000000000401', '00000000-0000-0000-0000-000000000101'),
  ('00000000-0000-0000-0000-000000000402', '00000000-0000-0000-0000-000000000102');

insert into public.research_studies (id, title, created_by) values
  ('00000000-0000-0000-0000-000000000601', 'RLS Fixture Study', '00000000-0000-0000-0000-000000000301');

insert into public.study_participants (
  study_id, student_id, participant_code, cohort, accent
) values
  ('00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000101', 'S001', 'control', 'us'),
  ('00000000-0000-0000-0000-000000000601', '00000000-0000-0000-0000-000000000102', 'S002', 'experimental', 'uk');

insert into public.content_items (id, type, text, content_version, publish_status) values
  ('00000000-0000-0000-0000-000000000501', 'word', 'think', 'fixture-v1', 'published');

insert into public.attempts (
  id, student_id, content_id, study_id, phase, accent, sync_state
) values
  ('00000000-0000-0000-0000-000000000701', '00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000501', '00000000-0000-0000-0000-000000000601', 'pretest', 'us', 'synced'),
  ('00000000-0000-0000-0000-000000000702', '00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000501', '00000000-0000-0000-0000-000000000601', 'pretest', 'uk', 'synced');

-- Student A: own profile/attempt visible, Student B data invisible.
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000101', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

do $$
begin
  if (select count(*) from public.profiles where id = '00000000-0000-0000-0000-000000000101') <> 1 then
    raise exception 'Student A cannot read own profile';
  end if;
  if (select count(*) from public.profiles where id = '00000000-0000-0000-0000-000000000102') <> 0 then
    raise exception 'Student A can read Student B profile';
  end if;
  if (select count(*) from public.attempts where id = '00000000-0000-0000-0000-000000000701') <> 1 then
    raise exception 'Student A cannot read own attempt';
  end if;
  if (select count(*) from public.attempts where id = '00000000-0000-0000-0000-000000000702') <> 0 then
    raise exception 'Student A can read Student B attempt';
  end if;
end $$;

reset role;

-- Teacher A: can read own class and Student A, cannot read Teacher B class/Student B.
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000201', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

do $$
begin
  if public.current_app_role() <> 'teacher'::public.app_role then
    raise exception 'Teacher A role helper mismatch';
  end if;
  if not public.teacher_owns_class('00000000-0000-0000-0000-000000000401') then
    raise exception 'Teacher A ownership helper rejected own class';
  end if;
  if public.teacher_owns_class('00000000-0000-0000-0000-000000000402') then
    raise exception 'Teacher A ownership helper accepted Teacher B class';
  end if;
  if not public.teacher_can_access_student('00000000-0000-0000-0000-000000000101') then
    raise exception 'Teacher A cannot access own class student';
  end if;
  if public.teacher_can_access_student('00000000-0000-0000-0000-000000000102') then
    raise exception 'Teacher A can access unrelated student';
  end if;
  if (select count(*) from public.classes where id = '00000000-0000-0000-0000-000000000401') <> 1 then
    raise exception 'Teacher A cannot read own class';
  end if;
  if (select count(*) from public.classes where id = '00000000-0000-0000-0000-000000000402') <> 0 then
    raise exception 'Teacher A can read Teacher B class';
  end if;
  if (select count(*) from public.profiles where id = '00000000-0000-0000-0000-000000000101') <> 1 then
    raise exception 'Teacher A cannot read own class student profile';
  end if;
  if (select count(*) from public.profiles where id = '00000000-0000-0000-0000-000000000102') <> 0 then
    raise exception 'Teacher A can read unrelated student profile';
  end if;
end $$;

reset role;

-- Anonymous users must not see research rows.
set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'anon', true);

do $$
begin
  if (select count(*) from public.research_studies) <> 0 then
    raise exception 'Anonymous user can read research studies';
  end if;
  if (select count(*) from public.study_participants) <> 0 then
    raise exception 'Anonymous user can read research participants';
  end if;
end $$;

reset role;
rollback;
