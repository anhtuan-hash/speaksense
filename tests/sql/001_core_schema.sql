\set ON_ERROR_STOP on

do $$
declare
  required_table text;
  required_tables text[] := array[
    'profiles',
    'classes',
    'class_members',
    'research_studies',
    'study_participants',
    'content_items',
    'pronunciation_references',
    'attempts',
    'attempt_scores',
    'pronunciation_errors',
    'human_reviews',
    'scoring_versions',
    'adaptive_versions',
    'consent_records',
    'audit_events'
  ];
begin
  foreach required_table in array required_tables loop
    if to_regclass(format('public.%I', required_table)) is null then
      raise exception '% table missing', required_table;
    end if;
  end loop;
end $$;

do $$
declare
  expected text[];
  actual text[];
begin
  if to_regtype('public.app_role') is null then
    raise exception 'app_role enum missing';
  end if;

  select array_agg(enumlabel order by enumsortorder)
    into actual
  from pg_enum
  where enumtypid = 'public.app_role'::regtype;
  expected := array['student','teacher','admin'];
  if actual <> expected then
    raise exception 'app_role values mismatch: %', actual;
  end if;

  if to_regtype('public.study_cohort') is null then
    raise exception 'study_cohort enum missing';
  end if;
  select array_agg(enumlabel order by enumsortorder)
    into actual
  from pg_enum
  where enumtypid = 'public.study_cohort'::regtype;
  expected := array['control','experimental'];
  if actual <> expected then
    raise exception 'study_cohort values mismatch: %', actual;
  end if;

  if to_regtype('public.accent_profile') is null then
    raise exception 'accent_profile enum missing';
  end if;
  select array_agg(enumlabel order by enumsortorder)
    into actual
  from pg_enum
  where enumtypid = 'public.accent_profile'::regtype;
  expected := array['us','uk'];
  if actual <> expected then
    raise exception 'accent_profile values mismatch: %', actual;
  end if;

  if to_regtype('public.content_type') is null then
    raise exception 'content_type enum missing';
  end if;
  select array_agg(enumlabel order by enumsortorder)
    into actual
  from pg_enum
  where enumtypid = 'public.content_type'::regtype;
  expected := array['word','sentence','passage'];
  if actual <> expected then
    raise exception 'content_type values mismatch: %', actual;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'research_studies'
      and column_name = 'status'
  ) then
    raise exception 'research_studies.status missing';
  end if;

  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'study_participants'
      and c.contype = 'u'
      and pg_get_constraintdef(c.oid) like '%study_id, student_id%'
  ) then
    raise exception 'study_participants unique(study_id, student_id) missing';
  end if;
end $$;
