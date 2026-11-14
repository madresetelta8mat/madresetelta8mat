-- SECTOR ISOLATION — APPLIED 2026-11-14 (~16:49-17:05 EET), verified: 17 v3 policies present, 0 replaced policies remaining.
-- Rule (Tomas): nobody sees servants or students outside their own sector; priests/admins (is_admin_or_priest) stay global.
-- Assistant policies were extended from their verified live quals (attendance: is_assistant(); notifications insert: is_assistant();
-- system-servant update students: role='student' AND caller is system_servant) with the sector condition ANDed in.
-- The executable form applied live also included the create-then-drop swaps executed block by block; this file records the resulting v3 definitions.

-- SECTOR ISOLATION — DRAFT (apply one block at a time after approval; verify after each)
create or replace function public.my_sector()
returns uuid language sql stable security definer set search_path = public as $$
  select sector_id from public.profiles where id = auth.uid();
$$;
create or replace function public.person_sector(p_id uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select sector_id from public.profiles where id = p_id;
$$;

-- profiles
create policy "staff read profiles v3" on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin_or_priest() or (public.is_staff() and sector_id = public.my_sector()));
drop policy "staff read profiles" on public.profiles;
create policy "assistant read profiles v3" on public.profiles for select to authenticated
  using (public.is_assistant() and sector_id = public.my_sector());
drop policy "assistant read profiles" on public.profiles;
-- system servant update students: recreate with sector condition (qual copied from live at apply time, plus: and sector_id = public.my_sector())

-- visits
create policy "staff read visits v3" on public.visits for select to authenticated
  using (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(student_id) = public.my_sector()));
create policy "staff insert visits v3" on public.visits for insert to authenticated
  with check (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(student_id) = public.my_sector()));
create policy "staff update visits v3" on public.visits for update to authenticated
  using (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(student_id) = public.my_sector()))
  with check (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(student_id) = public.my_sector()));
create policy "staff delete visits v3" on public.visits for delete to authenticated
  using (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(student_id) = public.my_sector()));
drop policy "staff read visits" on public.visits;
drop policy "staff insert visits" on public.visits;
drop policy "staff update visits" on public.visits;
drop policy "staff delete visits" on public.visits;

-- exams
create policy "staff manage exams v3" on public.exams for all to authenticated
  using (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(student_id) = public.my_sector()))
  with check (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(student_id) = public.my_sector()));
drop policy "staff manage exams" on public.exams;

-- student_tasks
create policy "staff read student_tasks v3" on public.student_tasks for select to authenticated
  using (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(student_id) = public.my_sector()));
create policy "staff update student_tasks v3" on public.student_tasks for update to authenticated
  using (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(student_id) = public.my_sector()))
  with check (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(student_id) = public.my_sector()));
drop policy "staff read student_tasks" on public.student_tasks;
drop policy "staff update student_tasks" on public.student_tasks;

-- attendance (staff v2 -> v3; assistant policies get the sector condition ANDed into their live quals at apply time)
create policy "staff insert attendance v3" on public.attendance for insert to authenticated
  with check (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(person_id) = public.my_sector()));
create policy "staff read attendance v3" on public.attendance for select to authenticated
  using (public.is_admin_or_priest() or (public.is_staff() and public.person_sector(person_id) = public.my_sector()));
drop policy "staff insert attendance v2" on public.attendance;
drop policy "staff read attendance v2" on public.attendance;

-- servants (empty legacy table — consistency)
create policy "staff manage servants v3" on public.servants for all to authenticated
  using (public.is_admin_or_priest() or auth_user_id = auth.uid() or (public.is_staff() and sector_id = public.my_sector()))
  with check (public.is_admin_or_priest() or auth_user_id = auth.uid() or (public.is_staff() and sector_id = public.my_sector()));
drop policy "staff manage servants" on public.servants;
create policy "servants_select_v3" on public.servants for select to authenticated
  using (public.is_admin_or_priest() or auth_user_id = auth.uid() or sector_id = public.my_sector());
drop policy "servants_select_v2" on public.servants;

-- notifications: assistant insert scoped (recreate with live qual + sector condition at apply time)

-- leaderboard_data() — replaced with the sector-scoped visibility condition (applied + verified 2026-11-14 ~17:11):
-- priests/admins see all students; other staff see only their sector (p.sector_id = me.sector_id);
-- servants-table branch got the same sector condition; student own-class branch unchanged.
-- Original definition is preserved in supabase-schema-backup.sql.
create or replace function public.leaderboard_data()
returns table(id uuid, full_name text, class_id uuid, class_name text, profile_image_url text, points bigint, attendance_days bigint)
language sql stable security definer set search_path to 'public'
as $function$
  select p.id, p.full_name, p.class_id, c.name, p.profile_image_url,
    coalesce((select sum(st.points_earned) from student_tasks st where st.student_id = p.id), 0)::bigint,
    coalesce((select count(distinct (a.attended_at at time zone 'Africa/Cairo')::date) from attendance a where a.person_id = p.id and a.person_type = 'student'), 0)::bigint
  from profiles p left join classes c on c.id = p.class_id
  where p.role = 'student' and coalesce(p.approved, false) = true
    and (
      exists (select 1 from profiles me where me.id = auth.uid() and me.role in ('priest', 'admin'))
      or exists (select 1 from profiles me where me.id = auth.uid() and me.role <> 'student' and p.sector_id = me.sector_id)
      or exists (select 1 from servants sv where (sv.auth_user_id = auth.uid() or lower(sv.email) = lower(auth.jwt() ->> 'email')) and p.sector_id = sv.sector_id)
      or p.class_id = (select me.class_id from profiles me where me.id = auth.uid())
    )
$function$;
