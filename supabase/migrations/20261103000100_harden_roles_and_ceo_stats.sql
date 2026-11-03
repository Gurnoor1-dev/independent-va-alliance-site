-- Harden function execution and let CEOs maintain their own pilot metrics.
revoke execute on function public.admin_update_va(uuid,text,text,text,text,text,text,text[],integer,integer,text) from public,anon;
revoke execute on function public.assign_reviewer(uuid,uuid) from public,anon;
revoke execute on function public.ceo_update_va(text,text,text,text,text[],text) from public,anon;
revoke execute on function public.complete_registration(text) from public,anon;
revoke execute on function public.create_registration_invite(text,text,uuid) from public,anon;
revoke execute on function public.current_role() from public,anon;
revoke execute on function public.is_admin() from public,anon;
revoke execute on function public.lookup_reservation(text) from public;
revoke execute on function public.set_application_status(uuid,text,text) from public,anon;
revoke execute on function public.submit_application(text,text,text,text,text,text,text,boolean,text,boolean) from public;
revoke execute on function public.submit_application_review(uuid,text,text) from public,anon;
grant execute on function public.admin_update_va(uuid,text,text,text,text,text,text,text[],integer,integer,text),public.assign_reviewer(uuid,uuid),public.ceo_update_va(text,text,text,text,text[],text),public.complete_registration(text),public.create_registration_invite(text,text,uuid),public.current_role(),public.is_admin(),public.set_application_status(uuid,text,text),public.submit_application_review(uuid,text,text) to authenticated;
grant execute on function public.lookup_reservation(text),public.submit_application(text,text,text,text,text,text,text,boolean,text,boolean) to anon,authenticated;
revoke all on table public.registration_codes from anon,authenticated;
create index if not exists profiles_va_idx on public.profiles(va_id);
create index if not exists application_assignments_assigned_by_idx on public.application_assignments(assigned_by);
create index if not exists application_reviews_reviewer_idx on public.application_reviews(reviewer_id);
create index if not exists events_va_idx on public.community_events(va_id);
create index if not exists events_creator_idx on public.community_events(created_by);
create index if not exists registration_codes_va_idx on public.registration_codes(va_id);
create index if not exists registration_codes_creator_idx on public.registration_codes(created_by);
drop function public.ceo_update_va(text,text,text,text,text[],text);
create function public.ceo_update_va(p_name text,p_website text,p_logo text,p_discord text,p_routes text[],p_description text,p_active integer,p_total integer)
returns void language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
 if public.current_role()<>'ceo' then raise exception 'CEO access required';end if;
 select va_id into v_id from public.profiles where id=auth.uid();
 update public.directory_vas set name=p_name,website_url=p_website,logo_url=p_logo,discord_url=p_discord,routes=coalesce(p_routes,'{}'),description=p_description,active_pilots=greatest(p_active,0),total_pilots=greatest(p_total,0) where id=v_id;
end $$;
revoke execute on function public.ceo_update_va(text,text,text,text,text[],text,integer,integer) from public,anon;
grant execute on function public.ceo_update_va(text,text,text,text,text[],text,integer,integer) to authenticated;
drop policy if exists "CEO create events" on public.community_events;
create policy "CEO create events" on public.community_events for insert to authenticated with check(public.current_role()='ceo' and va_id=(select va_id from public.profiles where id=auth.uid()) and created_by=(select auth.uid()));
drop policy if exists "CEO edit own events" on public.community_events;
create policy "CEO edit own events" on public.community_events for update to authenticated using(public.current_role()='ceo' and va_id=(select va_id from public.profiles where id=auth.uid())) with check(public.current_role()='ceo' and va_id=(select va_id from public.profiles where id=auth.uid()) and created_by=(select auth.uid()));
