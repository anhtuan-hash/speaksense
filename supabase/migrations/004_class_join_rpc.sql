-- Secure class creation and join-code flow.
-- Plaintext join codes are returned only by creation/rotation RPCs and are
-- never persisted in public.classes.

create unique index if not exists classes_join_code_hash_key
on public.classes(join_code_hash)
where join_code_hash is not null;

create or replace function public.create_class_with_code(
  p_name text,
  p_grade smallint
)
returns table (
  class_id uuid,
  class_name text,
  class_grade smallint,
  join_code text
)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_code text;
  v_hash text;
  v_class_id uuid;
  v_name text := btrim(p_name);
begin
  if v_actor is null or public.current_app_role() <> 'teacher'::public.app_role then
    raise exception using errcode = '42501', message = 'Only teachers can create classes';
  end if;

  if v_name is null or length(v_name) not between 1 and 120 then
    raise exception using errcode = '22023', message = 'Class name is required';
  end if;

  if p_grade is null or p_grade not in (10, 11, 12) then
    raise exception using errcode = '22023', message = 'Grade must be 10, 11, or 12';
  end if;

  loop
    v_code := upper(encode(extensions.gen_random_bytes(5), 'hex'));
    v_hash := encode(extensions.digest(v_code, 'sha256'), 'hex');
    exit when not exists (
      select 1 from public.classes c where c.join_code_hash = v_hash
    );
  end loop;

  insert into public.classes (
    teacher_id,
    name,
    grade,
    join_code_hash,
    join_code_active,
    active
  ) values (
    v_actor,
    v_name,
    p_grade,
    v_hash,
    true,
    true
  )
  returning id into v_class_id;

  return query
  select v_class_id, v_name, p_grade, v_code;
end;
$$;

create or replace function public.rotate_class_join_code(p_class_id uuid)
returns text
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_role public.app_role;
  v_teacher_id uuid;
  v_active boolean;
  v_code text;
  v_hash text;
begin
  if v_actor is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  v_role := public.current_app_role();
  if v_role not in ('teacher'::public.app_role, 'admin'::public.app_role) then
    raise exception using errcode = '42501', message = 'Only teachers or admins can rotate class codes';
  end if;

  select c.teacher_id, c.active
  into v_teacher_id, v_active
  from public.classes c
  where c.id = p_class_id
  for update;

  if not found then
    raise exception using errcode = '22023', message = 'Class not found';
  end if;

  if v_role = 'teacher'::public.app_role and v_teacher_id <> v_actor then
    raise exception using errcode = '42501', message = 'You do not own this class';
  end if;

  if not v_active then
    raise exception using errcode = '55000', message = 'Inactive classes cannot rotate join codes';
  end if;

  loop
    v_code := upper(encode(extensions.gen_random_bytes(5), 'hex'));
    v_hash := encode(extensions.digest(v_code, 'sha256'), 'hex');
    exit when not exists (
      select 1 from public.classes c where c.join_code_hash = v_hash
    );
  end loop;

  update public.classes
  set join_code_hash = v_hash,
      join_code_active = true,
      updated_at = now()
  where id = p_class_id;

  return v_code;
end;
$$;

create or replace function public.join_class_by_code(p_code text)
returns table (
  class_id uuid,
  student_id uuid,
  status public.membership_status
)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_student_id uuid := auth.uid();
  v_normalized text := upper(btrim(p_code));
  v_hash text;
  v_class_id uuid;
  v_existing_status public.membership_status;
begin
  if v_student_id is null or public.current_app_role() <> 'student'::public.app_role then
    raise exception using errcode = '42501', message = 'Only students can join classes';
  end if;

  if v_normalized is null or v_normalized = '' then
    raise exception using errcode = '22023', message = 'Join code is required';
  end if;

  v_hash := encode(extensions.digest(v_normalized, 'sha256'), 'hex');

  select c.id
  into v_class_id
  from public.classes c
  where c.join_code_hash = v_hash
    and c.join_code_active = true
    and c.active = true
  limit 1;

  if v_class_id is null then
    raise exception using errcode = '22023', message = 'Invalid or inactive class code';
  end if;

  select cm.status
  into v_existing_status
  from public.class_members cm
  where cm.class_id = v_class_id
    and cm.student_id = v_student_id
  for update;

  if found then
    if v_existing_status <> 'active'::public.membership_status then
      raise exception using
        errcode = '55000',
        message = 'Class membership is not active; ask your teacher';
    end if;

    return query
    select v_class_id, v_student_id, v_existing_status;
    return;
  end if;

  insert into public.class_members (class_id, student_id, status)
  values (v_class_id, v_student_id, 'active')
  on conflict on constraint class_members_pkey do nothing;

  select cm.status
  into v_existing_status
  from public.class_members cm
  where cm.class_id = v_class_id
    and cm.student_id = v_student_id;

  if v_existing_status <> 'active'::public.membership_status then
    raise exception using
      errcode = '55000',
      message = 'Class membership is not active; ask your teacher';
  end if;

  return query
  select v_class_id, v_student_id, v_existing_status;
end;
$$;

revoke all on function public.create_class_with_code(text, smallint) from public;
revoke all on function public.rotate_class_join_code(uuid) from public;
revoke all on function public.join_class_by_code(text) from public;

grant execute on function public.create_class_with_code(text, smallint) to authenticated;
grant execute on function public.rotate_class_join_code(uuid) to authenticated;
grant execute on function public.join_class_by_code(text) to authenticated;
