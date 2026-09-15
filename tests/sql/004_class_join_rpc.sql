\set ON_ERROR_STOP on

begin;

-- Contract: the student-facing class flow must only be available through
-- authenticated SECURITY DEFINER RPCs. These assertions intentionally fail
-- before migration 004 exists.
do $$
begin
  if to_regprocedure('public.create_class_with_code(text,smallint)') is null then
    raise exception 'create_class_with_code(text,smallint) missing';
  end if;
  if to_regprocedure('public.rotate_class_join_code(uuid)') is null then
    raise exception 'rotate_class_join_code(uuid) missing';
  end if;
  if to_regprocedure('public.join_class_by_code(text)') is null then
    raise exception 'join_class_by_code(text) missing';
  end if;
end $$;

-- Isolated principals for class-code behavior.
insert into auth.users (
  id, aud, role, email, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000001101', 'authenticated', 'authenticated', 'join-student@example.test', '', '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('00000000-0000-0000-0000-000000001201', 'authenticated', 'authenticated', 'join-teacher-a@example.test', '', '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('00000000-0000-0000-0000-000000001202', 'authenticated', 'authenticated', 'join-teacher-b@example.test', '', '{"provider":"email","providers":["email"]}', '{}', now(), now());

insert into public.profiles (id, role, display_name, username) values
  ('00000000-0000-0000-0000-000000001101', 'student', 'Join Student', 'join.student'),
  ('00000000-0000-0000-0000-000000001201', 'teacher', 'Join Teacher A', null),
  ('00000000-0000-0000-0000-000000001202', 'teacher', 'Join Teacher B', null);

-- Teacher A creates a Grade 11 class and receives plaintext only in the RPC response.
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000001201', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

create temporary table created_class as
select * from public.create_class_with_code('11A1 Pronunciation', 11::smallint);

do $$
declare
  v_class_id uuid;
  v_code text;
  v_hash text;
begin
  select class_id, join_code into v_class_id, v_code from created_class;
  if v_class_id is null or v_code !~ '^[A-F0-9]{10}$' then
    raise exception 'Create-class RPC did not return a 10-character code';
  end if;

  reset role;
  select join_code_hash into v_hash from public.classes where id = v_class_id;
  if v_hash is null or v_hash = v_code then
    raise exception 'Plaintext join code was stored in classes';
  end if;
end $$;

-- Capture the original code before rotation.
create temporary table original_code as select class_id, join_code from created_class;

-- Unrelated Teacher B cannot rotate Teacher A's code.
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000001202', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

do $$
declare
  v_class_id uuid := (select class_id from original_code);
begin
  begin
    perform public.rotate_class_join_code(v_class_id);
    raise exception 'Unrelated teacher rotated another teacher class';
  exception
    when insufficient_privilege then null;
  end;
end $$;

-- Teacher A rotates the code; the old code must immediately become invalid.
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000001201', true);
create temporary table rotated_code as
select public.rotate_class_join_code((select class_id from original_code)) as join_code;

do $$
begin
  if (select join_code from rotated_code) = (select join_code from original_code) then
    raise exception 'Rotation returned the previous code';
  end if;
end $$;

-- Student cannot join with the rotated-out old code.
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000001101', true);

do $$
begin
  begin
    perform public.join_class_by_code((select join_code from original_code));
    raise exception 'Old rotated join code was accepted';
  exception
    when invalid_parameter_value then null;
  end;
end $$;

-- Current code joins successfully and duplicate calls are idempotent.
create temporary table first_join as
select * from public.join_class_by_code((select join_code from rotated_code));
create temporary table second_join as
select * from public.join_class_by_code(lower((select join_code from rotated_code)));

do $$
declare
  v_class_id uuid := (select class_id from original_code);
begin
  if (select class_id from first_join) <> v_class_id then
    raise exception 'Valid join returned wrong class';
  end if;
  if (select student_id from first_join) <> '00000000-0000-0000-0000-000000001101'::uuid then
    raise exception 'Valid join returned wrong student';
  end if;
  if (select status::text from first_join) <> 'active' then
    raise exception 'Valid join did not return active membership';
  end if;
  if (select count(*) from public.class_members where class_id = v_class_id and student_id = '00000000-0000-0000-0000-000000001101') <> 1 then
    raise exception 'Duplicate join created duplicate membership';
  end if;
  if (select status::text from second_join) <> 'active' then
    raise exception 'Idempotent duplicate join did not return active membership';
  end if;
end $$;

-- A suspended membership cannot be silently reactivated with a class code.
reset role;
update public.class_members
set status = 'suspended'
where class_id = (select class_id from original_code)
  and student_id = '00000000-0000-0000-0000-000000001101';

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000001101', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

do $$
begin
  begin
    perform public.join_class_by_code((select join_code from rotated_code));
    raise exception 'Suspended membership was silently reactivated';
  exception
    when object_not_in_prerequisite_state then null;
  end;
end $$;

rollback;
