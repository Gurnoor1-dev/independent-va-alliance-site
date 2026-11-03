create or replace function public.set_application_status(p_application_id uuid,p_status text,p_decision_notes text default null)
returns text language plpgsql security definer set search_path=public
as $$
declare a public.applications%rowtype;code text;
begin
 if not public.is_admin() then raise exception 'Administrator access required';end if;
 if p_status not in('being_reviewed','approved','rejected') then raise exception 'Invalid status';end if;
 select * into a from public.applications where id=p_application_id for update;
 if not found then raise exception 'Application not found';end if;
 if p_status='being_reviewed' then
  if a.status<>'waiting' then raise exception 'This application is already in review';end if;
  loop
   code:=lpad((floor(random()*100000)::int)::text,5,'0');
   exit when not exists(select 1 from public.applications where reservation_code=code);
  end loop;
  update public.applications set status='being_reviewed',reservation_code=code where id=p_application_id;
  return code;
 elsif p_status='approved' then
  if a.status<>'being_reviewed' then raise exception 'Move the application into review before approving it';end if;
  if not exists(select 1 from public.application_reviews where application_id=p_application_id) then raise exception 'At least one assigned reviewer must submit a review before final approval';end if;
  insert into public.directory_vas(name,kind,ceo_ifc_username,website_url,description)
  values(a.name,a.kind,a.ceo_ifc_username,a.website_url,a.operations_plan)
  on conflict(name) do update set ceo_ifc_username=excluded.ceo_ifc_username,website_url=excluded.website_url;
  insert into public.application_archive(id,name,kind,ceo_ifc_username,email,status,decision_notes,submitted_at)
  values(a.id,a.name,a.kind,a.ceo_ifc_username,a.email,'approved',p_decision_notes,a.created_at);
  delete from public.applications where id=p_application_id;
  return 'APPROVED';
 else
  insert into public.application_archive(id,name,kind,ceo_ifc_username,email,status,decision_notes,submitted_at)
  values(a.id,a.name,a.kind,a.ceo_ifc_username,a.email,'rejected',p_decision_notes,a.created_at);
  delete from public.applications where id=p_application_id;
  return 'REJECTED';
 end if;
end $$;
revoke execute on function public.set_application_status(uuid,text,text) from public,anon;
grant execute on function public.set_application_status(uuid,text,text) to authenticated;
