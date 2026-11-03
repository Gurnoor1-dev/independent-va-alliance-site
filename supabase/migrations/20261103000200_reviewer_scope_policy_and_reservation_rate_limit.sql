-- Correct reviewer scope, harden role policies and rate-limit reservation lookups.
create schema if not exists private;
revoke all on schema private from public,anon,authenticated;
create table if not exists private.reservation_attempts(ip_hash text not null,attempted_at timestamptz not null default now());
create index if not exists reservation_attempts_ip_time_idx on private.reservation_attempts(ip_hash,attempted_at desc);
create or replace function public.lookup_reservation(p_code text)
returns table(application_id uuid,organisation_name text,organisation_type text,ceo_ifc_username text,status text,submitted_at timestamptz)
language plpgsql security definer set search_path=public,private,extensions as $$
declare headers jsonb;ip_value text;ip_digest text;attempt_count integer;
begin
 headers:=coalesce(nullif(current_setting('request.headers',true),''),'{}')::jsonb;
 ip_value:=coalesce(nullif(headers->>'cf-connecting-ip',''),nullif(split_part(coalesce(headers->>'x-forwarded-for',''),',',1),''));
 if ip_value is not null then
  ip_digest:=encode(extensions.digest(trim(ip_value),'sha256'),'hex');
  select count(*) into attempt_count from private.reservation_attempts where ip_hash=ip_digest and attempted_at>now()-interval '10 minutes';
  if attempt_count>=8 then raise exception 'Too many reservation lookups. Please try again in 10 minutes.';end if;
  insert into private.reservation_attempts(ip_hash) values(ip_digest);
 end if;
 return query select a.id,a.name,a.kind,a.ceo_ifc_username,a.status,a.created_at from public.applications a where a.reservation_code=upper(trim(p_code)) and a.status='being_reviewed' limit 1;
end$$;
revoke execute on function public.lookup_reservation(text) from public;
grant execute on function public.lookup_reservation(text) to anon,authenticated;
drop policy if exists "Assigned reviewers view applications" on public.applications;
create policy "Admin and assigned reviewer application read" on public.applications for select to authenticated
using ((select public.is_admin()) or exists(select 1 from public.application_assignments aa where aa.application_id=applications.id and aa.reviewer_id=(select auth.uid())));
drop policy if exists "Admins manage profiles" on public.profiles;
drop policy if exists "Users can view their own profile" on public.profiles;
drop policy if exists "Admin profiles" on public.profiles;
drop policy if exists "Own profile" on public.profiles;
create policy "Profile owner or admin read" on public.profiles for select to authenticated using(id=(select auth.uid()) or (select public.is_admin()));
create policy "Admin profile insert" on public.profiles for insert to authenticated with check((select public.is_admin()));
create policy "Admin profile update" on public.profiles for update to authenticated using((select public.is_admin())) with check((select public.is_admin()));
create policy "Admin profile delete" on public.profiles for delete to authenticated using((select public.is_admin()));
drop policy if exists "Admins manage assignments" on public.application_assignments;
drop policy if exists "Admins view assignments" on public.application_assignments;
create policy "Reviewer or admin assignment read" on public.application_assignments for select to authenticated using(reviewer_id=(select auth.uid()) or (select public.is_admin()));
create policy "Admin assignment insert" on public.application_assignments for insert to authenticated with check((select public.is_admin()));
create policy "Admin assignment update" on public.application_assignments for update to authenticated using((select public.is_admin())) with check((select public.is_admin()));
create policy "Admin assignment delete" on public.application_assignments for delete to authenticated using((select public.is_admin()));
drop policy if exists "Reviewers view own reviews" on public.application_reviews;
create policy "Reviewer or admin review read" on public.application_reviews for select to authenticated using(reviewer_id=(select auth.uid()) or (select public.is_admin()));
drop policy if exists "Admins manage events" on public.community_events;
drop policy if exists "CEOs create events" on public.community_events;
drop policy if exists "CEOs manage own events" on public.community_events;
drop policy if exists "CEO create events" on public.community_events;
drop policy if exists "CEO edit own events" on public.community_events;
create policy "CEO or admin event insert" on public.community_events for insert to authenticated with check((select public.is_admin()) or ((select public.current_role())='ceo' and va_id=(select p.va_id from public.profiles p where p.id=(select auth.uid())) and created_by=(select auth.uid())));
create policy "CEO or admin event update" on public.community_events for update to authenticated using((select public.is_admin()) or ((select public.current_role())='ceo' and va_id=(select p.va_id from public.profiles p where p.id=(select auth.uid())) and created_by=(select auth.uid()))) with check((select public.is_admin()) or ((select public.current_role())='ceo' and va_id=(select p.va_id from public.profiles p where p.id=(select auth.uid())) and created_by=(select auth.uid())));
create policy "Admin event delete" on public.community_events for delete to authenticated using((select public.is_admin()));
drop policy if exists "Admins manage staff" on public.staff_members;
drop policy if exists "Public can view active staff" on public.staff_members;
drop policy if exists "Active staff directory" on public.staff_members;
drop policy if exists "Admin staff management" on public.staff_members;
create policy "Public active staff or admin read" on public.staff_members for select to anon,authenticated using(active=true or (select public.is_admin()));
create policy "Admin staff insert" on public.staff_members for insert to authenticated with check((select public.is_admin()));
create policy "Admin staff update" on public.staff_members for update to authenticated using((select public.is_admin())) with check((select public.is_admin()));
create policy "Admin staff delete" on public.staff_members for delete to authenticated using((select public.is_admin()));
drop policy if exists "Admins manage support requests" on public.support_requests;
drop policy if exists "Anyone can submit support request" on public.support_requests;
drop policy if exists "Admin support management" on public.support_requests;
drop policy if exists "Public support submit" on public.support_requests;
create policy "Public support request insert" on public.support_requests for insert to anon,authenticated with check(true);
create policy "Admin support read" on public.support_requests for select to authenticated using((select public.is_admin()));
create policy "Admin support update" on public.support_requests for update to authenticated using((select public.is_admin())) with check((select public.is_admin()));
create policy "Admin support delete" on public.support_requests for delete to authenticated using((select public.is_admin()));
drop policy if exists "Admins view archive" on public.application_archive;
drop policy if exists "Admin archive read" on public.application_archive;
create policy "Admin archive read" on public.application_archive for select to authenticated using((select public.is_admin()));
create policy "No direct registration code access" on public.registration_codes for all to anon,authenticated using(false) with check(false);
