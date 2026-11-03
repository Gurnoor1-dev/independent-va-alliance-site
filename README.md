# Independent VA Alliance — Website & member platform

React + Vite public website and member portal backed by Supabase.

## Features
- Editorial landing page, About, VA database and organisation detail, staff directory, VA/VO creation guide, application, reservation lookup, events, support and resource hub.
- Supabase-backed application queue, reservation codes, archive, directory, staff, events and support requests.
- CEO, reviewer and administrator workspaces with role-aware access.
- Reviewer assignment and review submission; admin decisions, invitation issuance, directory and staff management.
- RLS-enabled schema and guarded database RPCs.

## Run
~~~sh
npm install
npm run dev
npm run build
~~~

Public project URL and publishable key are configured in `src/lib/supabase.js`; optional overrides are `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`. Never put a service-role or secret key in the frontend.

## First administrator
The first admin must be bootstrapped once from the Supabase SQL Editor. Create the admin's user in Authentication → Users → Add user, then insert the profile (replace both values):
~~~sql
insert into public.profiles (id, ifc_username, role)
values ('AUTH_USER_UUID', 'YOUR_IFC_USERNAME', 'admin');
~~~
After that, create CEO and reviewer invitations from Admin → Users & invites.

## Username-based Auth setting
Supabase Auth normally signs in with email or phone. To support the requested IFC username + password, this app maps the invited username to a synthetic address ending in `@iva-login.invalid`. In Supabase Dashboard → Authentication → Providers → Email, disable **Confirm email** for this username-only flow. Synthetic addresses are not deliverable; application contact email remains separate. For email confirmation, implement a trusted server-side identity broker with real member email addresses.

## Security and scope
- Browser uses the publishable key only.
- Applications are created and transitioned through database functions.
- Reservation lookup only returns records in `being_reviewed`; approval/rejection archives the record and removes the active application, invalidating its code.
- Registration codes are SHA-256 hashed, single-use and expire after seven days.
- First-admin bootstrap is intentionally manual; no public admin escalation endpoint exists.
- Visual identity is original IVA work inspired by the uploaded editorial / colourful motion reference, not a reproduction of another organisation's protected content.
