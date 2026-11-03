drop policy if exists "Public active staff or admin read" on public.staff_members;
create policy "Public active staff read" on public.staff_members for select to anon using(active=true);
create policy "Authenticated active staff or admin read" on public.staff_members for select to authenticated using(active=true or (select public.is_admin()));
