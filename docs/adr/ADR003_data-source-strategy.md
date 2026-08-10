# ADR 004: Start with Strava as the primary data source, expand later

**Status:** Accepted
**Date:** 2026-08-08

**Supersedes:** the data source decision in ADR 001, which assumed Garmin
Connect would be the initial ingestion point.

## Context

The project ingests personal training and health data. Three sources can
provide that data, and they differ significantly in what they expose, how they
are accessed, and what risk each carries.

**Strava** offers a documented public API with OAuth authorisation. Registering
an application yields client credentials; the user authorises specific scopes,
and the application receives an access token that is refreshed periodically. No
password is handled by the application, access can be revoked by the user at any
time, and rate limits are documented. The data available is centred on
activities: distance, pace, duration, heart rate during exercise, power,
segments. It does not include continuous health metrics.

**Garmin Connect** has no public API for individual developers. The practical
route is `python-garminconnect`, a community library that authenticates through
the same SSO flow as the website. It exposes considerably more: daily steps,
sleep, resting heart rate, stress, body battery, SpO2, HRV, respiration,
intensity minutes, body composition, and training metrics such as VO2 max and
training readiness — the entire recovery side of the picture, which is absent
from Strava. The cost is that this use is not sanctioned: it likely violates
Garmin's terms of service, may break without warning when Garmin changes its
backend, and carries a small risk of rate limiting or account restriction.

**Apple Health** aggregates data from connected devices, including Garmin, and
contains the same daily health metrics. However, HealthKit is a device-local
API: reading it programmatically requires an iOS application running on the
phone itself, with explicit user permission. There is no web API. The only
non-programmatic route is a manual export, which produces a large XML archive.

An important nuance: if a Garmin device is connected to Strava, activities
recorded by the watch appear in Strava automatically. Strava can therefore serve
as an officially sanctioned route to a meaningful portion of Garmin's activity
data — but never to the daily health metrics, which are not synced.

## Decision

Build the ingestion layer against **Strava** first, using its official OAuth
API. Design the data model and pipeline so that additional sources can be added
without restructuring.

Garmin Connect is planned as a second source once the pipeline is proven,
specifically to obtain the daily health metrics that Strava does not provide.
Apple Health is not planned.

## Rationale

The purpose of the first ingestion is to prove the pipeline: authenticate,
fetch, normalise, persist, and do so idempotently. Doing that against a
documented API with predictable behaviour isolates the variable — a failure is
almost certainly in the project's code, not in an undocumented dependency that
may have changed overnight.

Starting with the source that carries risk would conflate two problems. If
ingestion fails, is the model wrong, or did the library break? Establishing a
working baseline first makes the second source a substitution rather than an
investigation.

There is also a sequencing benefit specific to this project: by the time Garmin
is introduced, the schema, the persistence logic and the idempotency guarantees
will already exist and be tested. Adding a source becomes a matter of writing a
client and a mapper.

Apple Health was rejected because the effort is disproportionate. Building an
iOS application to extract data that Garmin exposes directly adds an entire
platform to the project without providing anything the Garmin route does not.

## Consequences

### Positive

- No credentials are handled by the application; OAuth tokens are scoped and
  revocable.
- The API is documented, so rate limits and response shapes are known in advance
  rather than discovered empirically.
- No terms-of-service concern for the initial implementation.
- Activities recorded on a Garmin device are still reachable, via the Strava
  sync.

### Negative

- Strava alone cannot answer the questions that motivated the project. Sleep
  quality, resting heart rate and recovery metrics are the interesting half of
  the analysis, and none of them are available. The first working version of the
  pipeline will therefore be less useful than the eventual one.
- OAuth introduces token lifecycle management (expiry, refresh, storage) that a
  simpler authentication scheme would not require. This is worth doing correctly
  from the start, since it is the same pattern most production integrations use.
- Two sources means reconciliation: the same activity may arrive from both
  Strava and Garmin and must not be duplicated.

## Implications for the data model

This decision makes multi-source support structural rather than incidental, and
two consequences follow:

**Every record needs a source attribution.** A `fonte` field must identify where
each record originated, and the model must tolerate the same logical event
arriving from more than one source.

**Activities and daily metrics are different grains and should be separate
tables.** An activity is a discrete event — several may occur on one day, or
none. A daily metric is one row per day by definition. The originally drafted
`fato_saude_diaria` conflated the two by embedding `duracao_treino_minutos` in
the daily row, which silently assumes at most one workout per day. Separating
them into a daily fact and an activity fact, both keyed to `dim_data`, removes
that assumption.

Deduplication strategy between sources is deferred until Garmin is actually
introduced, but the schema should not make it harder than necessary.

### Revisit when

Reconsider when the Strava-based pipeline is stable and the daily health metrics
become the blocking gap in the analysis. At that point, evaluate whether to use
the unofficial Garmin library or to fall back on Garmin's manual account export,
which produces the same data without the terms-of-service concern at the cost of
being a manual step.