# PROJECT_WEBAPP.md

**Version:** 1.0.0
**Layer:** 3 of 4 (Project overlay)
**Inherits:** CLAUDE.md + role overlay (Forge/Quill/Scout)

**EXAMPLE OVERLAY.** This file demonstrates the project overlay pattern for a full-stack web application. Replace it with your own using `PROJECT_TEMPLATE.md`, or delete it if you have no web app in this repo.

## Project identity

ExampleApp is a full-stack web application. Frontend: React with TypeScript. Backend: Node.js with Express. Database: PostgreSQL via Prisma. Auth: NextAuth with email/password and OAuth providers. Hosted at example.com.

## Non-negotiable rules

- All user-input fields validated server-side; client validation is convenience only
- Authentication state never lives only in client storage
- Database migrations are forward-only; never edit a committed migration
- Production secrets live in the environment, never in code or committed files
- All API endpoints rate-limited; new endpoints must declare a rate limit

## Language and naming

- Use "user" for the authenticated identity, "account" for the billing entity
- Use "tenant" for organizations; users belong to tenants
- API endpoints: `/api/v1/<resource>`, kebab-case for multi-word resources
- Database tables: snake_case plural; columns: snake_case
- React components: PascalCase; hooks: `use` prefix in camelCase
- Use "session" for the authenticated session; "token" only for API tokens

## Engineering constraints

- Server actions and API routes must validate input with Zod schemas
- Database queries through Prisma; raw SQL requires comment explaining why
- All async functions handle errors; no unhandled promise rejections
- New routes require a test that covers at least one happy path and one error case
- Component props are typed; no `any` in component signatures

## Active scope

- `app/` and `src/` are active
- `legacy/` is frozen; surface any task that implies changes here
- Database schema changes require an operator review before migration runs

## Handoff context

- Forge can implement directly in this codebase
- Operator reviews any change to auth, billing, or schema before merge

## Role-specific notes

### Forge-specific notes when working on this project

- Verify whether a route is public or authenticated before any change
- New components match the existing Tailwind utility patterns in neighboring files
- API responses use the existing response envelope; do not invent a new shape

### Quill-specific notes when working on this project

- API docs distinguish authenticated from public endpoints explicitly
- Error response documentation includes the exact HTTP status and response body shape

### Scout-specific notes when working on this project

- When tracing a request, follow the path from route handler through service layer to database
- Auth-related issues require checking session middleware as the first step
- Surface any endpoint that lacks rate limiting

## Glossary

| Term | Meaning |
|---|---|
| Tenant | Organization-level account |
| User | Individual authenticated identity within a tenant |
| Session | Authenticated browser session |
| Token | API token for programmatic access |

## Open questions

- Multi-region deployment strategy
- Tenant-level data export and deletion workflows
