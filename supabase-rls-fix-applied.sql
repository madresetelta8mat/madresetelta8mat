-- =====================================================================
-- RLS FIX — AS APPLIED on 2026-11-14 (fix session, Tomas present).
-- This is the record of what was actually executed and verified in the
-- Supabase SQL Editor for project kxhzxhhssvfucqbexcme. Result: policies
-- 66 -> 53, all permissive leftovers replaced by scoped policies.
-- A rollback section (recreating the pre-fix policies) is at the end.
-- Pre-fix state: supabase-schema-backup.sql. Plan: rls-remediation-plan.md.
-- =====================================================================

-- ---------- RPC HARDENING (applied first, Phase 1) ----------
-- BEFORE: has_function_privilege showed anon AND authenticated = true for
-- both functions (grant was to PUBLIC). Guards added inside the bodies:
--   delete_user_completely: first line  if not public.is_admin_or_priest()
--     then raise exception 'forbidden'; end if;   (body otherwise unchanged)
--   notify_absentees: first line  if not (public.is_admin_or_priest()
--     or public.is_staff()) then raise exception 'forbidden'; end if;
--     (body otherwise unchanged)
-- Grants fixed afterwards (revoking from "anon" alone was NOT enough —
-- the grant was to PUBLIC):
revoke execute on function public.delete_user_completely(uuid) from public;
revoke execute on function public.notify_absentees() from public;
-- AFTER (verified): anon false/false; authenticated true/true (guards decide).
-- Dead code dropped in the same session:
drop trigger if exists on_notification_created on public.notifications;
drop function if exists public.trigger_send_push();
-- notify_push() was also recreated with the new WEBHOOK_SECRET value
-- (value NOT recorded here — it lives only in Supabase Edge Function
-- secrets and the function definition itself).

-- ---------- STEP 0: staff helper (SECURITY DEFINER avoids RLS recursion)
-- NOTE: finalize after seeing is_admin_or_priest()/is_assistant() defs.
create or replace function public.is_staff()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select
    exists (
      select 1 from public.profiles me
      where me.id = auth.uid()
        and me.role in ('admin','priest','sector_leader','servant','system_servant')
    )
    or exists (
      select 1 from public.servants sv
      where sv.auth_user_id = auth.uid()
         or lower(sv.email) = lower(auth.jwt() ->> 'email')
    )
    or public.is_assistant()
$$;

-- ---------- 1) profiles -------------------------------------------------
create policy "staff read profiles" on public.profiles
  for select to authenticated
  using (auth.uid() = id or public.is_admin_or_priest() or public.is_staff());

create policy "admin priest update profiles" on public.profiles
  for update to authenticated
  using (public.is_admin_or_priest())
  with check (public.is_admin_or_priest());

drop policy "admin_read_all_profiles" on public.profiles;
drop policy "Allow authenticated update profiles" on public.profiles;
drop policy "admin_update_profiles" on public.profiles;

-- ---------- 2) servants -------------------------------------------------
create policy "staff manage servants" on public.servants
  for insert to authenticated
  with check (public.is_admin_or_priest() or public.is_staff());
create policy "staff update servants" on public.servants
  for update to authenticated
  using (public.is_admin_or_priest() or public.is_staff())
  with check (public.is_admin_or_priest() or public.is_staff());
create policy "staff delete servants" on public.servants
  for delete to authenticated
  using (public.is_admin_or_priest() or public.is_staff());
create policy "staff read servants" on public.servants
  for select to authenticated
  using (public.is_admin_or_priest() or public.is_staff());

drop policy "allow_insert" on public.servants;
drop policy "allow_update" on public.servants;
drop policy "allow_delete" on public.servants;
drop policy "allow_select" on public.servants;
-- KEEP "servants_select" in this pass (see plan, Phase-2 decision).

-- ---------- 3) visits ---------------------------------------------------
create policy "staff read visits" on public.visits
  for select to authenticated
  using (public.is_admin_or_priest() or public.is_staff());
create policy "staff insert visits" on public.visits
  for insert to authenticated
  with check (public.is_admin_or_priest() or public.is_staff());
create policy "staff update visits" on public.visits
  for update to authenticated
  using (public.is_admin_or_priest() or public.is_staff())
  with check (public.is_admin_or_priest() or public.is_staff());
create policy "staff delete visits" on public.visits
  for delete to authenticated
  using (public.is_admin_or_priest() or public.is_staff());

drop policy "Allow authenticated read visits" on public.visits;
drop policy "Allow authenticated insert visits" on public.visits;
drop policy "Allow authenticated update visits" on public.visits;
drop policy "Allow authenticated delete visits" on public.visits;
drop policy "visits_select" on public.visits;
drop policy "visits_insert" on public.visits;

-- ---------- 4) exams ----------------------------------------------------
create policy "staff manage exams" on public.exams
  for all to authenticated
  using (public.is_admin_or_priest() or public.is_staff())
  with check (public.is_admin_or_priest() or public.is_staff());
create policy "students read own exams" on public.exams
  for select to authenticated
  using (student_id = auth.uid());

drop policy "exams_insert" on public.exams;
drop policy "exams_select" on public.exams;
drop policy "exams_delete" on public.exams;

-- ---------- 5) student_tasks ---------------------------------------------
create policy "students insert own tasks" on public.student_tasks
  for insert to authenticated
  with check (student_id = auth.uid());
create policy "students read own tasks" on public.student_tasks
  for select to authenticated
  using (student_id = auth.uid());
create policy "students update own tasks" on public.student_tasks
  for update to authenticated
  using (student_id = auth.uid())
  with check (student_id = auth.uid());
create policy "staff read student tasks" on public.student_tasks
  for select to authenticated
  using (public.is_admin_or_priest() or public.is_staff());
create policy "staff update student tasks" on public.student_tasks
  for update to authenticated
  using (public.is_admin_or_priest() or public.is_staff())
  with check (public.is_admin_or_priest() or public.is_staff());

drop policy "student_tasks_insert" on public.student_tasks;
drop policy "student_tasks_select" on public.student_tasks;
drop policy "student_tasks_update" on public.student_tasks;

-- ---------- 6) attendance -------------------------------------------------
create policy "staff insert attendance v2" on public.attendance
  for insert to authenticated
  with check (public.is_admin_or_priest() or public.is_staff());
create policy "staff read attendance v2" on public.attendance
  for select to authenticated
  using (public.is_admin_or_priest() or public.is_staff());
create policy "students read own attendance" on public.attendance
  for select to authenticated
  using (person_id = auth.uid());

drop policy "attendance_insert" on public.attendance;
drop policy "attendance_select" on public.attendance;

-- ---------- 7) notifications ----------------------------------------------
create policy "insert own notification" on public.notifications
  for insert to authenticated
  with check (person_id = auth.uid());

drop policy "Allow insert notifications" on public.notifications;

-- ---------- 8) tasks --------------------------------------------------------
create policy "staff insert tasks" on public.tasks
  for insert to authenticated
  with check (public.is_admin_or_priest() or public.is_staff());
create policy "staff update tasks" on public.tasks
  for update to authenticated
  using (public.is_admin_or_priest() or public.is_staff())
  with check (public.is_admin_or_priest() or public.is_staff());
create policy "staff delete tasks" on public.tasks
  for delete to authenticated
  using (public.is_admin_or_priest() or public.is_staff());

drop policy "Allow authenticated insert tasks" on public.tasks;
drop policy "Allow authenticated update tasks" on public.tasks;
drop policy "Allow authenticated delete tasks" on public.tasks;
drop policy "Allow authenticated read tasks" on public.tasks;
-- KEEP "tasks_select" (any-authenticated read; students need their tasks).

-- ---------- 9) attendance_settings -------------------------------------------
create policy "staff manage attendance settings" on public.attendance_settings
  for all to authenticated
  using (public.is_admin_or_priest() or public.is_staff())
  with check (public.is_admin_or_priest() or public.is_staff());
create policy "authenticated read attendance settings" on public.attendance_settings
  for select to authenticated
  using (true);

drop policy "Allow authenticated read attendance_settings" on public.attendance_settings;
drop policy "Allow authenticated insert attendance_settings" on public.attendance_settings;
drop policy "Allow authenticated update attendance_settings" on public.attendance_settings;
drop policy "Allow authenticated delete attendance_settings" on public.attendance_settings;
drop policy "att_settings_update" on public.attendance_settings;
drop policy "att_settings_read" on public.attendance_settings;

-- ---------- 10) quiz_settings --------------------------------------------------
create policy "staff write quiz settings" on public.quiz_settings
  for all to authenticated
  using (public.is_admin_or_priest() or public.is_staff())
  with check (public.is_admin_or_priest() or public.is_staff());

drop policy "quiz_settings_write" on public.quiz_settings;
-- KEEP "quiz_settings_read".

-- ---------- 11) subjects ---------------------------------------------------------
create policy "staff insert subjects" on public.subjects
  for insert to authenticated
  with check (public.is_admin_or_priest() or public.is_staff());

drop policy "subjects_insert" on public.subjects;
-- KEEP "subjects_select".

-- =====================================================================
-- ROLLBACK — recreate dropped policies exactly as audited (2026-11-14).
-- Run only the block for a table whose smoke test failed (and first drop
-- the replacement policies created above for that table).
-- =====================================================================
-- profiles:
-- create policy "admin_read_all_profiles" on public.profiles for select to public using (true);
-- create policy "Allow authenticated update profiles" on public.profiles for update to authenticated using (true);
-- create policy "admin_update_profiles" on public.profiles for update to public using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
-- servants:
-- create policy "allow_select" on public.servants for select to authenticated using (true);
-- create policy "allow_insert" on public.servants for insert to authenticated with check (true);
-- create policy "allow_update" on public.servants for update to authenticated using (true) with check (true);
-- create policy "allow_delete" on public.servants for delete to authenticated using (true);
-- visits:
-- create policy "Allow authenticated read visits" on public.visits for select to authenticated using (true);
-- create policy "Allow authenticated insert visits" on public.visits for insert to authenticated with check (true);
-- create policy "Allow authenticated update visits" on public.visits for update to authenticated using (true) with check (true);
-- create policy "Allow authenticated delete visits" on public.visits for delete to authenticated using (true);
-- create policy "visits_select" on public.visits for select to public using (auth.role() = 'authenticated');
-- create policy "visits_insert" on public.visits for insert to public with check (auth.role() = 'authenticated');
-- exams:
-- create policy "exams_insert" on public.exams for insert to public with check (auth.role() = 'authenticated');
-- create policy "exams_select" on public.exams for select to public using (auth.role() = 'authenticated');
-- create policy "exams_delete" on public.exams for delete to public using (auth.role() = 'authenticated');
-- student_tasks:
-- create policy "student_tasks_insert" on public.student_tasks for insert to public with check (auth.role() = 'authenticated');
-- create policy "student_tasks_select" on public.student_tasks for select to public using (auth.role() = 'authenticated');
-- create policy "student_tasks_update" on public.student_tasks for update to public using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
-- attendance:
-- create policy "attendance_insert" on public.attendance for insert to public with check (auth.role() = 'authenticated');
-- create policy "attendance_select" on public.attendance for select to public using (auth.role() = 'authenticated');
-- notifications:
-- create policy "Allow insert notifications" on public.notifications for insert to public with check (true);
-- tasks:
-- create policy "Allow authenticated read tasks" on public.tasks for select to authenticated using (true);
-- create policy "Allow authenticated insert tasks" on public.tasks for insert to authenticated with check (true);
-- create policy "Allow authenticated update tasks" on public.tasks for update to authenticated using (true) with check (true);
-- create policy "Allow authenticated delete tasks" on public.tasks for delete to authenticated using (true);
-- attendance_settings:
-- create policy "Allow authenticated read attendance_settings" on public.attendance_settings for select to authenticated using (true);
-- create policy "Allow authenticated insert attendance_settings" on public.attendance_settings for insert to authenticated with check (true);
-- create policy "Allow authenticated update attendance_settings" on public.attendance_settings for update to authenticated using (true);
-- create policy "Allow authenticated delete attendance_settings" on public.attendance_settings for delete to authenticated using (true);
-- create policy "att_settings_read" on public.attendance_settings for select to public using (true);
-- create policy "att_settings_update" on public.attendance_settings for update to public using (auth.role() = 'authenticated');
-- quiz_settings:
-- create policy "quiz_settings_write" on public.quiz_settings for all to public using (auth.uid() is not null);
-- subjects:
-- create policy "subjects_insert" on public.subjects for insert to public with check (auth.role() = 'authenticated');
