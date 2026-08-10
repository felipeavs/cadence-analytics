# Decision 001: Use psycopg (v3) as the PostgreSQL driver

**Status:** Accepted
**Date:** 2026-08-07

## Context

The project needs a PostgreSQL driver for Python — used both by Alembic when
applying migrations and, later, by the API when querying data.

`psycopg2-binary` is the conventional choice: it is what most tutorials assume,
what most existing projects use, and what SQLAlchemy documentation defaults to.
It was therefore the first driver installed.

During the initial Alembic setup, connecting through `psycopg2` failed on the
development machine (Windows) with a `UnicodeDecodeError` while decoding a
message returned by the server. The failure occurred inside the driver itself,
before any application code could handle it, and was unrelated to the connection
credentials — the same connection succeeded once the driver was replaced.

The likely cause is that the local PostgreSQL server emits messages in
Portuguese, and `psycopg2` on Windows decodes them using an encoding that does
not match the bytes actually returned. This is an environment-specific problem
rather than a fault in the project's configuration, but it makes `psycopg2`
unusable on this machine without workarounds.

## Decision

Use `psycopg` version 3 (installed as `psycopg[binary]`) as the PostgreSQL
driver, with connection URLs using the `postgresql+psycopg://` scheme.

## Rationale

Replacing the driver resolved the failure directly and with no workaround, which
matters more than following the more common convention — a driver that cannot
connect on the primary development machine is not a viable default, regardless
of how widely it is used elsewhere.

Beyond fixing the immediate problem, `psycopg` v3 is the actively developed line
of the library: v2 remains maintained but is no longer where new work happens.
Starting a new project on v3 avoids a migration later.

### Alternatives considered

- **Keep psycopg2 and force the client encoding** — setting `PGCLIENTENCODING`
  or adjusting the system locale might have worked, but it makes the project
  dependent on environment configuration that is not captured in the repository,
  and would likely resurface on any other Windows machine.
- **Keep psycopg2 and develop inside a container** — running Alembic from within
  a Linux container would sidestep the Windows-specific decoding issue entirely.
  This remains a reasonable option, but it makes the day-to-day loop slower for
  a problem that a driver swap solves outright.

## Consequences

### Positive

- Connections work reliably on the development machine, with no environment
  tweaks required.
- The project starts on the actively developed version of the library.
- `psycopg` v3 offers a native async interface, which may be useful if the API
  later moves to async database access.

### Negative

- Connection URLs must use the `postgresql+psycopg://` prefix. The bare
  `postgresql://` scheme resolves to psycopg2 in SQLAlchemy, so omitting the
  suffix produces a confusing "driver not installed" error. This is easy to
  forget and is worth checking first whenever a connection problem appears.
- Most tutorials, StackOverflow answers and existing code samples assume v2, so
  examples found online may need adapting.

### Revisit when

No revisit is anticipated. If the project later moves to a fully containerised
development workflow, the original encoding constraint would no longer apply —
but there would still be no reason to move back to v2.

## Related

A separate environment issue was diagnosed alongside this one: a PostgreSQL
instance installed natively on the development machine was occupying port 5432,
so connections intended for the container were silently reaching the wrong
server. The project's database is therefore exposed on port `5433` on the host.
This is documented in the README rather than as a decision record, since it is a
local environment accommodation rather than an architectural choice.