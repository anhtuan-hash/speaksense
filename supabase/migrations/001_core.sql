create extension if not exists pgcrypto with schema extensions;

create type public.app_role as enum ('student', 'teacher', 'admin');
create type public.study_cohort as enum ('control', 'experimental');
create type public.accent_profile as enum ('us', 'uk');
create type public.content_type as enum ('word', 'sentence', 'passage');
create type public.study_status as enum ('draft', 'frozen', 'active', 'completed', 'archived');
create type public.membership_status as enum ('active', 'suspended', 'removed');
create type public.version_status as enum ('draft', 'frozen', 'retired');
create type public.attempt_phase as enum ('practice', 'pretest', 'intervention', 'posttest');
create type public.sync_state as enum ('pending', 'syncing', 'synced', 'failed');
create type public.confidence_level as enum ('low', 'medium', 'high');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.app_role not null,
  display_name text not null check (length(btrim(display_name)) between 1 and 120),
  username text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint student_username_required check (role <> 'student' or username is not null),
  constraint username_format check (
    username is null or username ~ '^[a-z0-9._-]{3,40}$'
  )
);

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete restrict,
  name text not null check (length(btrim(name)) between 1 and 120),
  grade smallint not null check (grade in (10, 11, 12)),
  join_code_hash text,
  join_code_active boolean not null default true,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index classes_teacher_id_idx on public.classes(teacher_id);

create trigger classes_set_updated_at
before update on public.classes
for each row execute function public.set_updated_at();

create table public.class_members (
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete restrict,
  status public.membership_status not null default 'active',
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (class_id, student_id)
);

create index class_members_student_id_idx on public.class_members(student_id);

create trigger class_members_set_updated_at
before update on public.class_members
for each row execute function public.set_updated_at();

create table public.scoring_versions (
  id uuid primary key default gen_random_uuid(),
  version_name text not null unique,
  component_weights jsonb not null default '{}'::jsonb,
  thresholds jsonb not null default '{}'::jsonb,
  algorithm_metadata jsonb not null default '{}'::jsonb,
  status public.version_status not null default 'draft',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  frozen_at timestamptz,
  constraint scoring_frozen_timestamp check (
    status <> 'frozen' or frozen_at is not null
  )
);

create table public.adaptive_versions (
  id uuid primary key default gen_random_uuid(),
  version_name text not null unique,
  need_score_rules jsonb not null default '{}'::jsonb,
  content_allocation_rules jsonb not null default '{}'::jsonb,
  status public.version_status not null default 'draft',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  frozen_at timestamptz,
  constraint adaptive_frozen_timestamp check (
    status <> 'frozen' or frozen_at is not null
  )
);

create table public.research_studies (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(btrim(title)) between 1 and 180),
  status public.study_status not null default 'draft',
  starts_on date,
  ends_on date,
  scoring_version_id uuid references public.scoring_versions(id) on delete restrict,
  adaptive_version_id uuid references public.adaptive_versions(id) on delete restrict,
  test_content_version text,
  reference_version_us text,
  reference_version_uk text,
  frozen_snapshot jsonb,
  audio_retention_days integer check (audio_retention_days is null or audio_retention_days >= 0),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  frozen_at timestamptz,
  constraint study_date_order check (
    starts_on is null or ends_on is null or ends_on >= starts_on
  ),
  constraint frozen_study_has_snapshot check (
    status <> 'frozen' or (frozen_snapshot is not null and frozen_at is not null)
  )
);

create index research_studies_status_idx on public.research_studies(status);

create trigger research_studies_set_updated_at
before update on public.research_studies
for each row execute function public.set_updated_at();

create table public.study_participants (
  id uuid primary key default gen_random_uuid(),
  study_id uuid not null references public.research_studies(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete restrict,
  participant_code text not null check (length(btrim(participant_code)) between 1 and 40),
  cohort public.study_cohort not null,
  accent public.accent_profile not null,
  participation_status text not null default 'active' check (
    participation_status in ('active', 'withdrawn', 'completed', 'excluded')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint study_participants_study_student_key unique (study_id, student_id),
  constraint study_participants_code_key unique (study_id, participant_code)
);

create index study_participants_student_id_idx on public.study_participants(student_id);

create trigger study_participants_set_updated_at
before update on public.study_participants
for each row execute function public.set_updated_at();

create table public.content_items (
  id uuid primary key default gen_random_uuid(),
  type public.content_type not null,
  text text not null check (length(btrim(text)) > 0),
  grade_min smallint check (grade_min is null or grade_min in (10, 11, 12)),
  grade_max smallint check (grade_max is null or grade_max in (10, 11, 12)),
  target_tags text[] not null default '{}',
  publish_status text not null default 'draft' check (
    publish_status in ('draft', 'published', 'archived')
  ),
  content_version text not null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint content_grade_order check (
    grade_min is null or grade_max is null or grade_max >= grade_min
  )
);

create index content_items_type_idx on public.content_items(type);
create index content_items_version_idx on public.content_items(content_version);

create trigger content_items_set_updated_at
before update on public.content_items
for each row execute function public.set_updated_at();

create table public.pronunciation_references (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.content_items(id) on delete cascade,
  accent public.accent_profile not null,
  phonemes jsonb not null,
  syllables jsonb not null default '[]'::jsonb,
  stress_metadata jsonb not null default '{}'::jsonb,
  duration_metadata jsonb not null default '{}'::jsonb,
  reference_version text not null,
  created_at timestamptz not null default now(),
  constraint pronunciation_reference_version_key unique (content_id, accent, reference_version)
);

create index pronunciation_references_content_idx on public.pronunciation_references(content_id);
create index pronunciation_references_version_idx on public.pronunciation_references(reference_version);

create table public.attempts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete restrict,
  content_id uuid not null references public.content_items(id) on delete restrict,
  study_id uuid references public.research_studies(id) on delete restrict,
  phase public.attempt_phase not null default 'practice',
  accent public.accent_profile not null,
  device_metadata jsonb not null default '{}'::jsonb,
  audio_path text,
  audio_status text not null default 'none' check (
    audio_status in ('none', 'local', 'uploading', 'retained', 'deleted', 'failed')
  ),
  sync_state public.sync_state not null default 'pending',
  scoring_version_id uuid references public.scoring_versions(id) on delete restrict,
  exclusion_reason text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create index attempts_student_created_idx on public.attempts(student_id, created_at desc);
create index attempts_study_phase_idx on public.attempts(study_id, phase);

create table public.attempt_scores (
  attempt_id uuid primary key references public.attempts(id) on delete cascade,
  overall_score numeric(5,2) not null check (overall_score between 0 and 100),
  phoneme_accuracy numeric(5,2) not null check (phoneme_accuracy between 0 and 100),
  final_sounds numeric(5,2) not null check (final_sounds between 0 and 100),
  word_stress numeric(5,2) not null check (word_stress between 0 and 100),
  sentence_stress numeric(5,2) not null check (sentence_stress between 0 and 100),
  intonation numeric(5,2) not null check (intonation between 0 and 100),
  fluency numeric(5,2) not null check (fluency between 0 and 100),
  confidence numeric(5,4) not null check (confidence between 0 and 1),
  confidence_level public.confidence_level not null,
  metrics jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.pronunciation_errors (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.attempts(id) on delete cascade,
  error_family text not null,
  expected_unit text not null,
  observed_unit text,
  position jsonb not null default '{}'::jsonb,
  severity numeric(5,4) not null check (severity between 0 and 1),
  confidence numeric(5,4) not null check (confidence between 0 and 1),
  scoring_version_id uuid references public.scoring_versions(id) on delete restrict,
  created_at timestamptz not null default now()
);

create index pronunciation_errors_attempt_idx on public.pronunciation_errors(attempt_id);
create index pronunciation_errors_family_idx on public.pronunciation_errors(error_family);

create table public.human_reviews (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.attempts(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id) on delete restrict,
  human_scores jsonb not null,
  automated_snapshot_scores jsonb not null,
  absolute_difference numeric(6,2),
  notes text,
  submitted_at timestamptz not null default now(),
  constraint human_review_attempt_reviewer_key unique (attempt_id, reviewer_id)
);

create index human_reviews_reviewer_idx on public.human_reviews(reviewer_id, submitted_at desc);

create table public.consent_records (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete restrict,
  study_id uuid not null references public.research_studies(id) on delete cascade,
  consent_status boolean not null,
  audio_retention_permission boolean not null default false,
  consent_version text not null,
  recorded_at timestamptz not null default now(),
  revoked_at timestamptz,
  constraint consent_student_study_version_key unique (student_id, study_id, consent_version),
  constraint revoked_consent_timestamp check (
    consent_status or revoked_at is not null
  )
);

create index consent_records_study_idx on public.consent_records(study_id);

create table public.audit_events (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  entity_type text not null,
  entity_id uuid,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_events_entity_idx on public.audit_events(entity_type, entity_id, created_at desc);
create index audit_events_actor_idx on public.audit_events(actor_id, created_at desc);
