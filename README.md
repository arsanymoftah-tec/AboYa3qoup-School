# Abo Ya3qoup Professional (React + Vite + Supabase + Vercel)

## What is included
- Arabic RTL responsive dashboard with light/dark theme.
- Supabase email/password sign-in and pending-account gate.
- Role/status fields for admin activation workflow.
- Management sections: children, servants, classes, attendance, exams and announcements.
- Search, create/update/delete for active admins, summary cards and attendance overview.
- JSON backup export and JSON import preview with merge/replace modes.
- Vercel API health endpoint and baseline security headers.
- SQL schema with Row Level Security policies.

## Important limitations before production
- This is a professional starter/update foundation, not a guarantee that every workflow in any older HTML file has been ported. Review the supplied older pages and reconcile field names and workflows before replacing production.
- JSON export includes records the current signed-in user can read; import handles these six application tables only, not Supabase Auth accounts.
- Merge currently appends records; it does not intelligently deduplicate by a custom student code.
- The starter policies allow only active admins to write application records. A separate admin screen for activating accounts is not included yet; activate the first admin with SQL as below, then manage account approval in Supabase for now.
- Do not expose `SUPABASE_SERVICE_ROLE_KEY` in browser variables or commit `.env` files.
- Run the schema on a test project first. Existing production tables may have incompatible columns/policies; do not run migrations blindly on production.

## Local setup
1. Install Node.js (Termux: `pkg install nodejs git`).
2. Copy `.env.example` to `.env.local` and fill in the Supabase URL and public anon/publishable key.
3. Run `npm install`, then `npm run dev -- --host 0.0.0.0`.
4. Run `npm run build` to verify the production build.

## Supabase setup
1. Create/open your Supabase project.
2. Run `supabase/schema.sql` in SQL Editor after reviewing whether existing tables need migration.
3. Create a user through the app.
4. In Supabase SQL Editor, promote the intended first admin:
   `update public.profiles set role='admin', status='active' where id=(select id from auth.users where email='YOUR_EMAIL');`
5. In Supabase Auth settings, configure your site URL and allowed redirect URLs.

## Vercel deployment
- Import the repository or push this project to the same GitHub repo.
- In Vercel > Project > Settings > Environment Variables, set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` for Production (and Preview if needed).
- Redeploy after environment-variable changes.
- Never put the service role key in a `VITE_` variable.

## Replacing the old deployment safely
1. Back up current production data and download a copy of the old repository.
2. Test this version on a separate Vercel preview URL first.
3. Reconcile the SQL schema with your existing Supabase project; don't drop or overwrite tables blindly.
4. Confirm login, admin activation, CRUD and JSON export/import.
5. Only then push the tested version to the production branch.
