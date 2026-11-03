# Independent VA Alliance — IVA Platform

A React + Vite front-end foundation for the Independent VA Alliance.

## Run locally
```bash
npm install
npm run dev
```

## Current scope
- Public landing page and responsive navigation
- About, VA database, staff directory, creating a VA/VO, events, resources and support pages
- Application form UI and reservation-code verification UI
- Member sign-in / invitation registration UI
- CEO, Reviewer and Admin workspace previews
- Search, filtering, profile modal and responsive layouts

## Important: backend is not connected
This commit is a front-end foundation with illustrative sample directory data. Forms deliberately do not submit, authentication is not implemented, reservation codes are not validated, and dashboard actions are not live. Do not use it to collect real personal data or credentials.

Production functionality requires a connected backend with:
- Secure authentication and server-side role assignment (CEO / Reviewer / Admin)
- One-time, expiring invitation codes stored as hashes
- Application submissions, reservation codes, review assignments and audit history
- Row-level access controls so reviewers see only assigned applications
- Atomic approval workflow that converts an application into an approved organisation and invalidates the reservation code
- Secure email delivery, URL validation and rate-limited human verification
- VA/staff/event CRUD with role-scoped permissions

Supabase integration is a good fit, but no Supabase project is currently connected to this workspace. Never place a service-role key in browser code. The app should use a publishable key only, with RLS and Edge Functions for privileged operations.

## Design direction
Original IVA identity inspired by the supplied visual reference: restrained editorial typography, lavender/violet accents, generous whitespace, motion, and aviation-led graphic elements. IFVARB was reviewed for functional reference only; no brand assets or page copy are reused.
