# NAGI.rip

Premium customizable bio-link and digital identity platform.

## Stack
Next.js + TypeScript + Tailwind + Supabase + PostgreSQL.

## Local
1. Copy `.env.example` to `.env.local` and configure Supabase.
2. `npm install`
3. `npm run dev`
4. `npm run build`

## Render
Build: `npm install && npm run build`
Start: `npm start`
Health: `/api/health`

## Security
Never expose service-role, OAuth client secrets, or Stripe secret keys to the browser. Configure OAuth redirect URLs in the provider dashboards and enforce Supabase RLS on user-owned tables.

## Status
The repository contains the production UI foundation, routing, health endpoint, validation boundary, and deployment configuration. Supabase schema/auth/OAuth/payment integrations should be configured with the project's real credentials before accepting production users.