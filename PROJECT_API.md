# PROJECT_API.md

**Version:** 1.0.0
**Layer:** 3 of 4 (Project overlay)
**Inherits:** CLAUDE.md + role overlay (Forge/Quill/Scout)

**EXAMPLE OVERLAY.** This file demonstrates the project overlay pattern for a backend API service. Replace it with your own using `PROJECT_TEMPLATE.md`, or delete it if you have no API service in this repo.

## Project identity

ExampleAPI is a REST API service. Stack: Python with FastAPI, PostgreSQL via SQLAlchemy, Redis for caching, deployed on container infrastructure. Consumed by web frontend, mobile apps, and third-party integrations.

## Non-negotiable rules

- Every endpoint has an OpenAPI schema; missing schemas are a defect
- Breaking changes to public endpoints require a versioned route
- All endpoints emit structured logs with request ID, user ID (if authenticated), and latency
- PII never logged in plain text; redact at the logger layer
- Database write operations wrapped in transactions; partial writes are a defect

## Language and naming

- "Endpoint" refers to a route; "service" refers to internal business logic
- Public API uses `/v1/`, `/v2/` prefixes; internal admin uses `/admin/`
- Errors follow RFC 7807 problem details format
- Pagination uses cursor-based pattern with `?cursor=` and `?limit=`; no offset pagination
- Resource names plural in routes (`/users`, `/orders`), singular in code

## Engineering constraints

- Request/response models defined as Pydantic schemas; not raw dicts
- Service layer is stateless; state lives in the database or Redis
- Background work goes through the task queue; never block a request handler
- All external HTTP calls have explicit timeouts; no default infinite waits
- Database migrations run before deploy; schema and code are versioned together

## Active scope

- `app/api/v1/` is active for new endpoints
- `app/api/internal/` requires operator review for changes
- Deprecation of v1 endpoints requires written deprecation notice

## Handoff context

- Forge can implement directly
- API contract changes require Quill spec update before Forge implementation

## Role-specific notes

### Forge-specific notes when working on this project

- New endpoint requires schema, route, service function, test, and OpenAPI annotation
- Tests use the test client against the running app; not unit tests of route handlers in isolation
- Migrations created with the alembic CLI; never hand-edited migration files

### Quill-specific notes when working on this project

- Endpoint specs include request schema, response schema, error cases, and an example curl
- Breaking change docs go in the changelog with migration guidance

### Scout-specific notes when working on this project

- Trace performance issues through middleware, route handler, service, and database in that order
- Identify N+1 queries by reading the SQLAlchemy session log
- Cache-related issues require checking Redis state, not just code paths

## Glossary

| Term | Meaning |
|---|---|
| Endpoint | A single route in the API |
| Service | Internal business logic, called by endpoints |
| Task queue | Background work runner (separate from request lifecycle) |

## Open questions

- API gateway placement and rate limit enforcement layer
- Webhook delivery retry policy and dead-letter handling
