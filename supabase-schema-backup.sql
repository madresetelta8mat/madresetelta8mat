-- =====================================================================
-- SCHEMA BACKUP — Madraset El Toghmat El Sama2eya Lel Shamamsa
-- Supabase project ref: kxhzxhhssvfucqbexcme (eu-north-1, plan Nano)
-- Captured: 2026-11-14, read-only, via Supabase Dashboard SQL Editor
--   (pg_policies / pg_class audit + pg_get_functiondef, information_schema
--    .columns, pg_constraint, pg_indexes, information_schema.triggers)
-- Contents: 19 tables, 127 columns, 46 constraints, 3 plain indexes
--   (the remaining 20 of 23 indexes back PK/UNIQUE constraints and are
--    recreated by those constraints), 10 functions, 3 triggers,
--   RLS enabled on all 19 tables, 66 RLS policies.
-- This is a SCHEMA-ONLY snapshot. It contains NO data.
--
-- PREREQUISITES (must exist before running on a fresh project):
--   * Extensions: "pgcrypto" (gen_random_uuid()), "uuid-ossp"
--     (uuid_generate_v4()), and pg_net (net.http_post, used by
--     notify_push()/trigger_send_push(); on Supabase pg_net lives in the
--     "extensions" setup and provides the "net" schema).
--   * The Supabase "auth" schema (auth.users, auth.uid(), auth.jwt(),
--     auth.role()) — provided automatically by Supabase; three foreign
--     keys and push_subscriptions.user_id's default reference it.
-- =====================================================================

create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";
-- pg_net: enable via Supabase Dashboard → Database → Extensions (pg_net).

-- =====================================================================
-- 1) TABLES (19) — from information_schema.columns, 127 columns total
-- =====================================================================

create table public.activity_log (
  id bigint not null,
  created_at timestamptz not null default now(),
  user_id uuid,
  user_name text,
  user_role text,
  action text not null,
  details text
);

create table public.attendance (
  id uuid not null default uuid_generate_v4(),
  person_id uuid not null,
  person_type text not null,
  class_id uuid,
  attended_at timestamptz default now(),
  method text default 'qr'::text,
  notes text
);

create table public.attendance_settings (
  id uuid not null default uuid_generate_v4(),
  is_open boolean not null default false,
  opened_at timestamptz,
  closed_at timestamptz,
  opened_by uuid
);

create table public.classes (
  id uuid not null default uuid_generate_v4(),
  name text not null,
  sector_id uuid,
  grade_level integer,
  created_at timestamptz default now()
);

create table public.classes_backup (
  id uuid,
  name text,
  sector_id uuid,
  grade_level text,
  created_at timestamptz
);

create table public.exams (
  id uuid not null default uuid_generate_v4(),
  student_id uuid,
  subject_id uuid,
  exam_date timestamptz default now(),
  grade integer default 0,
  max_grade integer default 10,
  notes text,
  created_at timestamptz default now()
);

create table public.notifications (
  id uuid not null default gen_random_uuid(),
  person_id uuid not null,
  person_type text not null,
  type text not null,
  title text not null,
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.pending_approvals (
  id uuid not null,
  email text,
  created_at timestamptz default now()
);

create table public.profiles (
  id uuid not null,
  full_name text not null,
  phone text,
  whatsapp text,
  address text,
  birth_date date,
  role text not null default 'student'::text,
  class_id uuid,
  sector_id uuid,
  profile_image_url text,
  birth_cert_url text,
  unique_code text,
  qr_code_url text,
  approved boolean default false,
  created_at timestamptz default now(),
  email text,
  gender text,
  is_assistant boolean not null default false
);

create table public.profiles_backup (
  id uuid,
  class_id uuid,
  sector_id uuid
);

create table public.push_subscriptions (
  id uuid not null default gen_random_uuid(),
  person_id uuid not null,
  person_type text not null,
  endpoint text not null,
  subscription text not null,
  created_at timestamptz not null default now(),
  user_id uuid default auth.uid()
);

create table public.quiz_settings (
  id uuid not null default gen_random_uuid(),
  sector_id uuid,
  sheet_url text,
  sheet_url_liturgy text,
  sheet_url_coptic text,
  updated_by uuid,
  updated_at timestamptz default now()
);

create table public.sectors (
  id uuid not null default uuid_generate_v4(),
  name text not null,
  created_at timestamptz default now()
);

create table public.servants (
  id uuid not null default uuid_generate_v4(),
  full_name text not null,
  phone text,
  role text not null default 'servant'::text,
  class_id uuid,
  sector_id uuid,
  unique_code text default (uuid_generate_v4())::text,
  created_at timestamptz default now(),
  birth_date date,
  address text,
  confession_father text,
  profile_image_url text,
  profile_completed boolean default false,
  email text,
  auth_user_id uuid
);

create table public.servants_backup (
  id uuid,
  class_id uuid,
  sector_id uuid
);

create table public.student_tasks (
  id uuid not null default uuid_generate_v4(),
  student_id uuid,
  task_id uuid,
  points_earned integer default 0,
  completed boolean default false,
  completed_at timestamptz,
  created_at timestamptz default now()
);

create table public.subjects (
  id uuid not null default uuid_generate_v4(),
  name text not null,
  created_at timestamptz default now()
);

create table public.tasks (
  id uuid not null default uuid_generate_v4(),
  title text not null,
  description text,
  class_id uuid,
  points integer default 0,
  created_at timestamptz default now()
);

create table public.visits (
  id uuid not null default uuid_generate_v4(),
  student_id uuid,
  visit_date date not null default CURRENT_DATE,
  visit_type text not null,
  servant_id uuid,
  notes text,
  created_at timestamptz default now()
);

-- =====================================================================
-- 2) CONSTRAINTS (46) — from pg_constraint / pg_get_constraintdef()
-- =====================================================================

alter table public.activity_log add constraint activity_log_pkey primary key (id);

alter table public.attendance add constraint attendance_class_id_fkey foreign key (class_id) references classes(id) on delete set null;
alter table public.attendance add constraint attendance_method_check check ((method = any (array['qr'::text, 'manual'::text])));
alter table public.attendance add constraint attendance_person_type_check check ((person_type = any (array['student'::text, 'servant'::text])));
alter table public.attendance add constraint attendance_pkey primary key (id);

alter table public.attendance_settings add constraint attendance_settings_opened_by_fkey foreign key (opened_by) references profiles(id);
alter table public.attendance_settings add constraint attendance_settings_pkey primary key (id);

alter table public.classes add constraint classes_pkey primary key (id);
alter table public.classes add constraint classes_sector_id_fkey foreign key (sector_id) references sectors(id) on delete cascade;

alter table public.exams add constraint exams_pkey primary key (id);
alter table public.exams add constraint exams_student_id_fkey foreign key (student_id) references profiles(id) on delete cascade;
alter table public.exams add constraint exams_subject_id_fkey foreign key (subject_id) references subjects(id) on delete cascade;

alter table public.notifications add constraint notifications_person_type_check check ((person_type = any (array['student'::text, 'servant'::text])));
alter table public.notifications add constraint notifications_pkey primary key (id);

alter table public.pending_approvals add constraint pending_approvals_id_fkey foreign key (id) references auth.users(id) on delete cascade;
alter table public.pending_approvals add constraint pending_approvals_pkey primary key (id);

alter table public.profiles add constraint profiles_class_id_fkey foreign key (class_id) references classes(id) on delete set null;
alter table public.profiles add constraint profiles_gender_check check ((gender = any (array['male'::text, 'female'::text])));
alter table public.profiles add constraint profiles_id_fkey foreign key (id) references auth.users(id) on delete cascade;
alter table public.profiles add constraint profiles_pkey primary key (id);
alter table public.profiles add constraint profiles_role_check check ((role = any (array['student'::text, 'servant'::text, 'sector_leader'::text, 'priest'::text, 'admin'::text, 'system_servant'::text])));
alter table public.profiles add constraint profiles_sector_id_fkey foreign key (sector_id) references sectors(id);
alter table public.profiles add constraint profiles_unique_code_key unique (unique_code);

alter table public.push_subscriptions add constraint push_subscriptions_endpoint_key unique (endpoint);
alter table public.push_subscriptions add constraint push_subscriptions_person_type_check check ((person_type = any (array['student'::text, 'servant'::text])));
alter table public.push_subscriptions add constraint push_subscriptions_pkey primary key (id);

alter table public.quiz_settings add constraint quiz_settings_pkey primary key (id);
alter table public.quiz_settings add constraint quiz_settings_sector_id_fkey foreign key (sector_id) references sectors(id) on delete cascade;
alter table public.quiz_settings add constraint quiz_settings_sector_id_key unique (sector_id);
alter table public.quiz_settings add constraint quiz_settings_updated_by_fkey foreign key (updated_by) references auth.users(id);

alter table public.sectors add constraint sectors_pkey primary key (id);

alter table public.servants add constraint servants_class_id_fkey foreign key (class_id) references classes(id) on delete set null;
alter table public.servants add constraint servants_pkey primary key (id);
alter table public.servants add constraint servants_role_check check ((role = any (array['priest'::text, 'sector_leader'::text, 'servant'::text])));
alter table public.servants add constraint servants_sector_id_fkey foreign key (sector_id) references sectors(id);
alter table public.servants add constraint servants_unique_code_key unique (unique_code);

alter table public.student_tasks add constraint student_tasks_pkey primary key (id);
alter table public.student_tasks add constraint student_tasks_student_id_fkey foreign key (student_id) references profiles(id) on delete cascade;
alter table public.student_tasks add constraint student_tasks_task_id_fkey foreign key (task_id) references tasks(id) on delete cascade;

alter table public.subjects add constraint subjects_pkey primary key (id);

alter table public.tasks add constraint tasks_class_id_fkey foreign key (class_id) references classes(id) on delete set null;
alter table public.tasks add constraint tasks_pkey primary key (id);

alter table public.visits add constraint visits_pkey primary key (id);
alter table public.visits add constraint visits_servant_id_fkey foreign key (servant_id) references servants(id);
alter table public.visits add constraint visits_student_id_fkey foreign key (student_id) references profiles(id) on delete cascade;
alter table public.visits add constraint visits_visit_type_check check ((visit_type = any (array['phone'::text, 'home'::text])));

-- =====================================================================
-- 3) INDEXES — only the 3 plain CREATE INDEX statements from pg_indexes.
--    The other 20 indexes in the dump back the PK/UNIQUE constraints
--    above and are recreated automatically with them.
-- =====================================================================

create index activity_log_created_idx on public.activity_log using btree (created_at desc);
create index idx_notifications_person on public.notifications using btree (person_id, person_type, created_at desc);
create index idx_push_subs_person on public.push_subscriptions using btree (person_id, person_type);

-- =====================================================================
-- 4) FUNCTIONS (10) — VERBATIM from pg_get_functiondef(), 2026-11-14.
--    Single exception: the x-webhook-secret VALUE inside notify_push()
--    is redacted (see placeholder). trigger_send_push() is reproduced
--    exactly as found — it is a DEAD TEMPLATE (placeholder URL/key) and
--    is not the function that actually posts to send-push.
-- =====================================================================

CREATE OR REPLACE FUNCTION public.can_approve_profile(p_class uuid, p_sector uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public' AS $function$ select exists ( select 1 from profiles me where me.id = auth.uid() and (me.role in ('admin', 'priest', 'system_servant') or (me.role = 'sector_leader' and me.sector_id = p_sector) or (me.role = 'servant' and me.class_id = p_class)) ) or exists ( select 1 from servants sv where (sv.auth_user_id = auth.uid() or lower(sv.email) = lower(auth.jwt() ->> 'email')) and (sv.role = 'priest' or (sv.role = 'sector_leader' and sv.sector_id = p_sector) or (coalesce(sv.role, 'servant') = 'servant' and sv.class_id = p_class)) ) $function$;

CREATE OR REPLACE FUNCTION public.delete_user_completely(user_id uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $function$ begin delete from attendance where person_id = user_id; delete from visits where student_id = user_id; delete from student_tasks where student_id = user_id; delete from exams where student_id = user_id; delete from profiles where id = user_id; delete from auth.users where id = user_id; end; $function$;

CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $function$ begin insert into public.pending_approvals (id, email) values (new.id, new.email); return new; end; $function$;

CREATE OR REPLACE FUNCTION public.is_admin_or_priest() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public' AS $function$ select exists (select 1 from profiles me where me.id = auth.uid() and me.role in ('admin', 'priest')) or exists (select 1 from servants sv where (sv.auth_user_id = auth.uid() or lower(sv.email) = lower(auth.jwt() ->> 'email')) and sv.role = 'priest') $function$;

CREATE OR REPLACE FUNCTION public.is_assistant() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public' AS $function$ select coalesce((select is_assistant from profiles where id = auth.uid()), false) $function$;

CREATE OR REPLACE FUNCTION public.leaderboard_data() RETURNS TABLE(id uuid, full_name text, class_id uuid, class_name text, profile_image_url text, points bigint, attendance_days bigint) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public' AS $function$ select p.id, p.full_name, p.class_id, c.name, p.profile_image_url, coalesce((select sum(st.points_earned) from student_tasks st where st.student_id = p.id), 0)::bigint, coalesce((select count(distinct (a.attended_at at time zone 'Africa/Cairo')::date) from attendance a where a.person_id = p.id and a.person_type = 'student'), 0)::bigint from profiles p left join classes c on c.id = p.class_id where p.role = 'student' and coalesce(p.approved, false) = true and ( exists (select 1 from profiles me where me.id = auth.uid() and me.role <> 'student') or exists (select 1 from servants sv where sv.auth_user_id = auth.uid() or lower(sv.email) = lower(auth.jwt() ->> 'email')) or p.class_id = (select me.class_id from profiles me where me.id = auth.uid()) ) $function$;

CREATE OR REPLACE FUNCTION public.notify_absentees() RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $function$ declare today_start timestamptz := date_trunc('day', now()); today_end timestamptz := today_start + interval '1 day'; begin -- المخدومين الغايبين (موافق عليهم وملهم سجل حضور النهارده) insert into notifications (person_id, person_type, type, title, message) select p.id, 'student', 'absence_reminder', 'وحشتنا 🙏', 'وحشتنا جدا عايزين نشوفك المرة الجايه❤️❤️' from profiles p where p.role = 'student' and p.approved = true and not exists ( select 1 from attendance a where a.person_id = p.id and a.person_type = 'student' and a.attended_at >= today_start and a.attended_at < today_end ); -- الخدام الغايبين insert into notifications (person_id, person_type, type, title, message) select s.id, 'servant', 'absence_reminder', 'وحشتنا 🙏', 'افتقدناك انهارده جدا ❤️❤️❤️حاول تيجى المرة الجايه' from servants s where not exists ( select 1 from attendance a where a.person_id = s.id and a.person_type = 'servant' and a.attended_at >= today_start and a.attended_at < today_end ); end; $function$;

CREATE OR REPLACE FUNCTION public.notify_new_registration() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$ begin if new.role = 'student' and coalesce(new.approved, false) = false then insert into notifications (person_id, person_type, type, title, message) select id, 'servant', 'registration', 'طلب تسجيل جديد 🆕', coalesce(new.full_name, 'مخدوم جديد') || ' سجّل وبانتظار الموافقة. ادخل على صفحة الموافقات.' from servants where class_id = new.class_id or role = 'priest' or (role = 'sector_leader' and sector_id = new.sector_id) union select id, 'servant', 'registration', 'طلب تسجيل جديد 🆕', coalesce(new.full_name, 'مخدوم جديد') || ' سجّل وبانتظار الموافقة. ادخل على صفحة الموافقات.' from profiles where id <> new.id and (role in ('admin', 'priest', 'system_servant') or (role = 'servant' and class_id = new.class_id) or (role = 'sector_leader' and sector_id = new.sector_id)); end if; return new; exception when others then return new; -- مهما حصل، التسجيل ما يفشلش بسبب الإشعار end; $function$;

CREATE OR REPLACE FUNCTION public.notify_push() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'extensions', 'net' AS $function$ begin perform net.http_post( url := 'https://kxhzxhhssvfucqbexcme.supabase.co/functions/v1/send-push', headers := jsonb_build_object( 'Content-Type', 'application/json', 'x-webhook-secret', '<REDACTED — set the real WEBHOOK_SECRET value before use>' ), body := jsonb_build_object('type', 'INSERT', 'table', 'notifications', 'record', to_jsonb(new)) ); return new; exception when others then return new; -- لو الإرسال فشل، الإشعار نفسه يتسجل عادي end; $function$;

-- DEAD TEMPLATE — kept verbatim as found (placeholder URL and key; the
-- trigger on_notification_created below fires it on every notification,
-- and every call fails silently against the non-existent host).
CREATE OR REPLACE FUNCTION public.trigger_send_push() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $function$ begin perform net.http_post( url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-push', headers := jsonb_build_object( 'Content-Type', 'application/json', 'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY' ), body := jsonb_build_object( 'person_id', new.person_id, 'person_type', new.person_type, 'title', new.title, 'message', new.message ) ); return new; end; $function$;

-- =====================================================================
-- 5) TRIGGERS (3) — from information_schema.triggers
-- =====================================================================

create trigger on_notification_created
  after insert on public.notifications
  for each row execute function public.trigger_send_push();

create trigger push_on_notification
  after insert on public.notifications
  for each row execute function public.notify_push();

create trigger on_new_registration
  after insert on public.profiles
  for each row execute function public.notify_new_registration();

-- =====================================================================
-- 6) ROW LEVEL SECURITY — enabled on all 19 public tables
-- =====================================================================

alter table public.activity_log enable row level security;
alter table public.attendance enable row level security;
alter table public.attendance_settings enable row level security;
alter table public.classes enable row level security;
alter table public.classes_backup enable row level security;
alter table public.exams enable row level security;
alter table public.notifications enable row level security;
alter table public.pending_approvals enable row level security;
alter table public.profiles enable row level security;
alter table public.profiles_backup enable row level security;
alter table public.push_subscriptions enable row level security;
alter table public.quiz_settings enable row level security;
alter table public.sectors enable row level security;
alter table public.servants enable row level security;
alter table public.servants_backup enable row level security;
alter table public.student_tasks enable row level security;
alter table public.subjects enable row level security;
alter table public.tasks enable row level security;
alter table public.visits enable row level security;

-- =====================================================================
-- 7) RLS POLICIES (66) — reconstructed from pg_policies, 2026-11-14.
--    All policies are PERMISSIVE (default). Where the audit showed a
--    NULL with_check on an UPDATE/DELETE/ALL policy, the policy is
--    recreated with USING only (Postgres then applies USING as the
--    check expression too, matching live semantics). INSERT policies
--    carry WITH CHECK only; SELECT/DELETE carry USING only.
--    classes_backup, profiles_backup, servants_backup and
--    pending_approvals intentionally have NO policies (default-deny).
-- =====================================================================

-- ---- activity_log (2)
create policy "log insert own" on public.activity_log
  for insert to authenticated
  with check (user_id = auth.uid());

create policy "log read admin priest" on public.activity_log
  for select to authenticated
  using (is_admin_or_priest());

-- ---- attendance (4)
create policy "assistant insert attendance" on public.attendance
  for insert to authenticated
  with check (is_assistant());

create policy "assistant read attendance" on public.attendance
  for select to authenticated
  using (is_assistant());

create policy "attendance_insert" on public.attendance
  for insert to public
  with check ((auth.role() = 'authenticated'::text));

create policy "attendance_select" on public.attendance
  for select to public
  using ((auth.role() = 'authenticated'::text));

-- ---- attendance_settings (6)
create policy "Allow authenticated delete attendance_settings" on public.attendance_settings
  for delete to authenticated
  using (true);

create policy "Allow authenticated insert attendance_settings" on public.attendance_settings
  for insert to authenticated
  with check (true);

create policy "Allow authenticated read attendance_settings" on public.attendance_settings
  for select to authenticated
  using (true);

create policy "Allow authenticated update attendance_settings" on public.attendance_settings
  for update to authenticated
  using (true);

create policy "att_settings_read" on public.attendance_settings
  for select to public
  using (true);

create policy "att_settings_update" on public.attendance_settings
  for update to public
  using ((auth.role() = 'authenticated'::text));

-- ---- classes (4)
create policy "admin priest delete classes" on public.classes
  for delete to authenticated
  using (is_admin_or_priest());

create policy "admin priest insert classes" on public.classes
  for insert to authenticated
  with check (is_admin_or_priest());

create policy "admin priest update classes" on public.classes
  for update to authenticated
  using (is_admin_or_priest())
  with check (is_admin_or_priest());

create policy "classes_read" on public.classes
  for select to public
  using (true);

-- ---- exams (3)
create policy "exams_delete" on public.exams
  for delete to public
  using ((auth.role() = 'authenticated'::text));

create policy "exams_insert" on public.exams
  for insert to public
  with check ((auth.role() = 'authenticated'::text));

create policy "exams_select" on public.exams
  for select to public
  using ((auth.role() = 'authenticated'::text));

-- ---- notifications (5)
create policy "Allow insert notifications" on public.notifications
  for insert to public
  with check (true);

create policy "Users can update own notifications" on public.notifications
  for update to public
  using (((person_id = auth.uid()) or (person_id in ( select servants.id from servants where (servants.auth_user_id = auth.uid())))));

create policy "Users can view own notifications" on public.notifications
  for select to public
  using (((person_id = auth.uid()) or (person_id in ( select servants.id from servants where (servants.auth_user_id = auth.uid())))));

create policy "approvers insert notifications" on public.notifications
  for insert to authenticated
  with check (((exists ( select 1 from profiles me where ((me.id = auth.uid()) and (me.role = any (array['admin'::text, 'priest'::text, 'sector_leader'::text, 'servant'::text, 'system_servant'::text]))))) or (exists ( select 1 from servants sv where ((sv.auth_user_id = auth.uid()) or (lower(sv.email) = lower((auth.jwt() ->> 'email'::text))))))));

create policy "assistant insert notifications" on public.notifications
  for insert to authenticated
  with check (is_assistant());

-- ---- profiles (11)
create policy "Allow authenticated update profiles" on public.profiles
  for update to authenticated
  using (true);

create policy "admin_read_all_profiles" on public.profiles
  for select to public
  using (true);

create policy "admin_update_profiles" on public.profiles
  for update to public
  using ((auth.role() = 'authenticated'::text));

create policy "approvers approve students" on public.profiles
  for update to authenticated
  using (((role = 'student'::text) and can_approve_profile(class_id, sector_id)))
  with check (((role = 'student'::text) and can_approve_profile(class_id, sector_id)));

create policy "approvers read pending students" on public.profiles
  for select to authenticated
  using (((role = 'student'::text) and can_approve_profile(class_id, sector_id)));

create policy "approvers reject pending students" on public.profiles
  for delete to authenticated
  using (((role = 'student'::text) and (approved = false) and can_approve_profile(class_id, sector_id)));

create policy "assistant read profiles" on public.profiles
  for select to authenticated
  using (is_assistant());

create policy "profiles_insert_own" on public.profiles
  for insert to public
  with check ((auth.uid() = id));

create policy "profiles_select_own" on public.profiles
  for select to public
  using ((auth.uid() = id));

create policy "profiles_update_own" on public.profiles
  for update to public
  using ((auth.uid() = id));

create policy "system servant update students" on public.profiles
  for update to authenticated
  using (((role = 'student'::text) and (exists ( select 1 from profiles me where ((me.id = auth.uid()) and (me.role = 'system_servant'::text))))))
  with check (((role = 'student'::text) and (exists ( select 1 from profiles me where ((me.id = auth.uid()) and (me.role = 'system_servant'::text))))));

-- ---- push_subscriptions (4)
create policy "Users can manage own push subscription" on public.push_subscriptions
  for all to public
  using (((person_id = auth.uid()) or (person_id in ( select servants.id from servants where (servants.auth_user_id = auth.uid())))))
  with check (((person_id = auth.uid()) or (person_id in ( select servants.id from servants where (servants.auth_user_id = auth.uid())))));

create policy "push insert own" on public.push_subscriptions
  for insert to authenticated
  with check ((user_id = auth.uid()));

create policy "push read own" on public.push_subscriptions
  for select to authenticated
  using ((user_id = auth.uid()));

create policy "push update own" on public.push_subscriptions
  for update to authenticated
  using ((user_id = auth.uid()))
  with check ((user_id = auth.uid()));

-- ---- quiz_settings (2)
create policy "quiz_settings_read" on public.quiz_settings
  for select to public
  using (true);

create policy "quiz_settings_write" on public.quiz_settings
  for all to public
  using ((auth.uid() is not null));

-- ---- sectors (4)
create policy "admin priest delete sectors" on public.sectors
  for delete to authenticated
  using (is_admin_or_priest());

create policy "admin priest insert sectors" on public.sectors
  for insert to authenticated
  with check (is_admin_or_priest());

create policy "admin priest update sectors" on public.sectors
  for update to authenticated
  using (is_admin_or_priest())
  with check (is_admin_or_priest());

create policy "sectors_read" on public.sectors
  for select to public
  using (true);

-- ---- servants (5)
create policy "allow_delete" on public.servants
  for delete to authenticated
  using (true);

create policy "allow_insert" on public.servants
  for insert to authenticated
  with check (true);

create policy "allow_select" on public.servants
  for select to authenticated
  using (true);

create policy "allow_update" on public.servants
  for update to authenticated
  using (true);

create policy "servants_select" on public.servants
  for select to public
  using ((auth.role() = 'authenticated'::text));

-- ---- student_tasks (3)
create policy "student_tasks_insert" on public.student_tasks
  for insert to public
  with check ((auth.role() = 'authenticated'::text));

create policy "student_tasks_select" on public.student_tasks
  for select to public
  using ((auth.role() = 'authenticated'::text));

create policy "student_tasks_update" on public.student_tasks
  for update to public
  using ((auth.role() = 'authenticated'::text));

-- ---- subjects (2)
create policy "subjects_insert" on public.subjects
  for insert to public
  with check ((auth.role() = 'authenticated'::text));

create policy "subjects_select" on public.subjects
  for select to public
  using (true);

-- ---- tasks (5)
create policy "Allow authenticated delete tasks" on public.tasks
  for delete to authenticated
  using (true);

create policy "Allow authenticated insert tasks" on public.tasks
  for insert to authenticated
  with check (true);

create policy "Allow authenticated read tasks" on public.tasks
  for select to authenticated
  using (true);

create policy "Allow authenticated update tasks" on public.tasks
  for update to authenticated
  using (true);

create policy "tasks_select" on public.tasks
  for select to public
  using ((auth.role() = 'authenticated'::text));

-- ---- visits (6)
create policy "Allow authenticated delete visits" on public.visits
  for delete to authenticated
  using (true);

create policy "Allow authenticated insert visits" on public.visits
  for insert to authenticated
  with check (true);

create policy "Allow authenticated read visits" on public.visits
  for select to authenticated
  using (true);

create policy "Allow authenticated update visits" on public.visits
  for update to authenticated
  using (true);

create policy "visits_insert" on public.visits
  for insert to public
  with check ((auth.role() = 'authenticated'::text));

create policy "visits_select" on public.visits
  for select to public
  using ((auth.role() = 'authenticated'::text));

-- =====================================================================
-- KNOWN GAPS IN THIS BACKUP (read before relying on it):
--   * auth.users and the whole auth schema are NOT covered (Supabase-
--     managed). Three FKs point into it (profiles.id, pending_
--     approvals.id, quiz_settings.updated_by) and the auth.* helper
--     functions are assumed to exist.
--   * Storage (buckets, objects, storage policies) is NOT covered.
--     The app uses a "student-files" bucket (from client code) whose
--     definition was not part of this capture.
--   * handle_new_user() currently has NO trigger anywhere — in the
--     live project nothing calls it (it was presumably meant for an
--     auth.users insert trigger feeding pending_approvals, which is
--     therefore only populated manually / not at all).
--   * Edge Functions are NOT covered: send-push exists in the project
--     but had 0 invocations and NO custom secrets (VAPID_*/WEBHOOK_
--     SECRET unset) at capture time; its source was recorded in the
--     audit session notes, not in this file.
--   * No Database Webhooks exist in the dashboard (push is attempted
--     via the two DB triggers in section 5 instead).
--   * The x-webhook-secret value inside notify_push() is REDACTED
--     above; set the real value (matching the WEBHOOK_SECRET secret
--     of the send-push function) before using that function.
--   * activity_log.id is bigint NOT NULL with no default and no
--     sequence/identity visible in the captured queries — if the live
--     column is GENERATED ... AS IDENTITY, recreate it as
--     "bigint generated always as identity" (unverifiable from the
--     captured data; information_schema reports no default either way).
--   * DATA is not included — schema only.
-- =====================================================================
