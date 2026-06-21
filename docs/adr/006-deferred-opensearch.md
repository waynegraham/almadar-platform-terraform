# ADR-006: Deferred OpenSearch

Date: 2026-06-21

Status: Accepted

## Context

The platform includes public object discovery and search requirements, but the
initial collection scale is approximately 1,000 collection objects. The
repository's platform principles explicitly avoid introducing distributed search
or caching layers without a documented business requirement.

OpenSearch would add a dedicated service with indexing, backups, security,
monitoring, scaling, and disaster recovery responsibilities. At current scale,
the likely operational cost is higher than the immediate benefit.

## Decision

Defer OpenSearch.

Use simpler search and filtering approaches in the application and PostgreSQL
until real product requirements or measured performance limits justify a search
cluster. Revisit this decision when search requirements exceed what the current
application and database can support.

## Consequences

Positive consequences:

- Avoids operating a search cluster before it is needed.
- Keeps infrastructure simpler and cheaper for nonprofit budget constraints.
- Reduces disaster recovery scope.
- Allows search requirements to mature before selecting indexing and query
  architecture.

Negative consequences:

- Advanced search features may require later rework.
- PostgreSQL-backed or application-level search may be less capable than
  OpenSearch for relevance tuning, faceting, typo tolerance, and analytics.
- A future OpenSearch adoption will need migration planning, indexing jobs, and
  operational runbooks.

## Alternatives Considered

- Deploy OpenSearch immediately: rejected as premature operational complexity
  for the current collection size.
- Use a hosted search SaaS: may reduce operations but adds vendor dependency,
  recurring cost, and data export considerations.
- Use PostgreSQL full-text search now: acceptable as an incremental option if
  basic search needs grow, but it should be implemented in application code and
  documented separately.
- Use static prebuilt search indexes: viable for very small public search
  surfaces, but less suitable for frequently edited CMS content.
