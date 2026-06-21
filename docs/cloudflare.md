# Cloudflare Operations

Cloudflare provides DNS, TLS, CDN caching, WAF, and controlled access for the
AlMadar public platform. OCI and Kubernetes remain the source of truth for
origins. Cloudflare must route to those origins; it must not become the only
place where platform behavior is documented.

This document is for platform engineers who are new to the project and need to
recreate, verify, or operate the Cloudflare configuration.

## Hostnames

Use one Cloudflare zone for the production domain.

| Hostname | Purpose | Origin service | Cloudflare proxy |
| --- | --- | --- | --- |
| `www.<domain>` | Public Next.js frontend | OKE frontend service through OCI Load Balancer | Proxied |
| `cms.<domain>` | Strapi CMS admin and API | OKE Strapi service through OCI Load Balancer | Proxied |
| `api.<domain>` | Public Strapi content API, if separated from CMS UI | OKE Strapi service through OCI Load Balancer | Proxied |
| `iiif.<domain>` | IIIF image delivery | OKE Cantaloupe service through OCI Load Balancer | Proxied |

Replace `<domain>` with the actual production zone.

## DNS

Create DNS records after the OCI Load Balancer hostname is available.

Recommended records:

| Type | Name | Target | Proxy status | TTL |
| --- | --- | --- | --- | --- |
| `CNAME` | `www` | `<oci_lb_hostname>` | Proxied | Auto |
| `CNAME` | `cms` | `<oci_lb_hostname>` | Proxied | Auto |
| `CNAME` | `api` | `<oci_lb_hostname>` | Proxied | Auto |
| `CNAME` | `iiif` | `<oci_lb_hostname>` | Proxied | Auto |

If OCI provides only IP addresses, use `A` records instead. Keep all four
records proxied unless debugging requires temporarily exposing origin behavior.

Verification:

```bash
dig www.<domain>
dig cms.<domain>
dig api.<domain>
dig iiif.<domain>
curl -I https://www.<domain>
curl -I https://cms.<domain>
curl -I https://api.<domain>
curl -I https://iiif.<domain>
```

Expected result:

- DNS resolves through Cloudflare.
- HTTPS works for every hostname.
- Responses include Cloudflare headers such as `cf-ray`.

## OCI Load Balancer Integration

OKE services should expose application traffic through an OCI Load Balancer.
Cloudflare DNS records point to that load balancer, not directly to pods or
nodes.

Recommended origin layout:

```text
Client
  -> Cloudflare
  -> OCI Load Balancer
  -> OKE Service
  -> Kubernetes Pods
```

Recommended listener behavior:

| Load balancer listener | Backend service | Notes |
| --- | --- | --- |
| HTTPS `443` | frontend service | Origin certificate required |
| HTTPS `443` | strapi service | Route by hostname/path if using one shared LB |
| HTTPS `443` | cantaloupe service | Route `iiif.<domain>` to Cantaloupe |
| HTTP `80` | redirect only | Redirect to HTTPS or disable public HTTP |

If a single OCI Load Balancer fronts all apps, configure hostname-based routing:

- `www.<domain>` routes to the frontend backend set.
- `cms.<domain>` routes to the Strapi backend set.
- `api.<domain>` routes to the Strapi backend set.
- `iiif.<domain>` routes to the Cantaloupe backend set.

If the current OKE ingress controller manages this routing, document the ingress
class, ingress manifests, and generated load balancer hostname in the relevant
Kubernetes documentation.

Do not restrict the OCI Load Balancer to arbitrary static Cloudflare IPs unless
there is an automated process to keep Cloudflare IP ranges current. If origin
locking is required, prefer Cloudflare Authenticated Origin Pulls or mTLS and
document certificate rotation.

## SSL/TLS

Set Cloudflare SSL/TLS encryption mode to:

```text
Full (strict)
```

This requires Cloudflare-to-origin traffic to use HTTPS with a valid certificate
on the OCI Load Balancer.

Origin certificate options:

1. Cloudflare Origin CA certificate installed on the OCI Load Balancer.
2. Public CA certificate covering all four hostnames.

Required hostnames on the origin certificate:

```text
www.<domain>
cms.<domain>
api.<domain>
iiif.<domain>
```

Recommended SSL/TLS settings:

| Setting | Value |
| --- | --- |
| Encryption mode | Full (strict) |
| Always Use HTTPS | Enabled |
| Automatic HTTPS Rewrites | Enabled |
| Minimum TLS version | TLS 1.2 or newer |
| HTTP Strict Transport Security | Enable only after all hostnames are confirmed healthy |

HSTS rollout:

1. Verify all hostnames work over HTTPS.
2. Enable HSTS with a short max-age.
3. Monitor for one release cycle.
4. Increase max-age after confirming no mixed-content or certificate issues.
5. Do not enable preload until the team explicitly accepts the operational
   commitment.

## Origin Headers

Ensure applications receive the original client context from Cloudflare:

| Header | Use |
| --- | --- |
| `CF-Connecting-IP` | Original client IP |
| `X-Forwarded-For` | Proxy chain |
| `X-Forwarded-Proto` | Original scheme |
| `Host` | Hostname routing and app URL generation |

Kubernetes ingress or application middleware should trust forwarded headers only
from the OCI Load Balancer and Cloudflare path, not from arbitrary direct
clients.

## Cache Rules

Cloudflare cache behavior should be conservative for dynamic CMS and API
traffic. Cache images and static assets aggressively; bypass admin, preview, and
mutating API paths.

Create cache rules in this order.

### 1. Bypass Strapi Admin

Expression:

```text
(http.host eq "cms.<domain>" and starts_with(http.request.uri.path, "/admin"))
```

Action:

```text
Bypass cache
```

### 2. Bypass Strapi APIs

Expression:

```text
((http.host in {"cms.<domain>" "api.<domain>"}) and starts_with(http.request.uri.path, "/api"))
```

Action:

```text
Bypass cache
```

Use this as the default until the application defines explicit public cache
headers for safe read-only API responses.

### 3. Cache Frontend Static Assets

Expression:

```text
(http.host eq "www.<domain>" and starts_with(http.request.uri.path, "/_next/static/"))
```

Action:

```text
Eligible for cache
Edge TTL: 1 month
Browser TTL: Respect origin
```

### 4. Cache IIIF Tiles and Derivatives

Expression:

```text
(http.host eq "iiif.<domain>" and http.request.method eq "GET")
```

Action:

```text
Eligible for cache
Edge TTL: 1 week
Browser TTL: Respect origin
Cache key: include full path and query string
```

IIIF image requests are usually immutable for a given object identifier and
transformation path. If an object is replaced, purge the affected IIIF URL
prefix from Cloudflare.

### 5. Bypass Non-GET Requests

Expression:

```text
(http.request.method ne "GET" and http.request.method ne "HEAD")
```

Action:

```text
Bypass cache
```

## WAF Rules

Enable Cloudflare managed WAF rules for the zone. Keep custom rules small,
auditable, and tied to a clear platform risk.

Recommended custom WAF rules:

### Block Nonstandard Ports

Expression:

```text
(not cf.edge.server_port in {80 443})
```

Action:

```text
Block
```

### Block Direct Admin API Mutation From Public Internet

Expression:

```text
(http.host eq "cms.<domain>" and starts_with(http.request.uri.path, "/admin") and http.request.method in {"POST" "PUT" "PATCH" "DELETE"})
```

Action:

```text
Managed Challenge or Block
```

Use `Managed Challenge` while validating editor workflows. Move to `Block` only
if Cloudflare Access fully covers the admin hostname and no legitimate editor
traffic is blocked.

### Rate Limit CMS Authentication

Scope:

```text
cms.<domain>/admin/*
```

Recommended action:

```text
Managed Challenge
```

Tune thresholds from observed traffic. Avoid setting a low static number before
real editor usage is known.

### Protect IIIF From Excessive Scraping

Scope:

```text
iiif.<domain>/*
```

Recommended action:

```text
Managed Challenge or rate limit by IP
```

Start in log-only or challenge mode. IIIF viewers legitimately make many tile
requests, so aggressive rate limits can break normal object viewing.

## Access Rules For Strapi Admin

Protect Strapi admin with Cloudflare Access.

Create a self-hosted Access application:

| Field | Value |
| --- | --- |
| Application name | `AlMadar Strapi Admin` |
| Domain | `cms.<domain>` |
| Path | `/admin/*` |
| Session duration | 8 to 12 hours |

Create an allow policy:

| Policy item | Recommendation |
| --- | --- |
| Include | Project engineer and editor email addresses or approved email domain |
| Require | MFA-capable identity provider group, if available |
| Exclude | Former staff, blocked countries if required by policy |

Recommended identity providers:

- GitHub organization SSO for engineers.
- Google Workspace or Microsoft Entra ID for editors, if used by the project.

Do not protect the entire `cms.<domain>` hostname unless public Strapi API
traffic has moved to `api.<domain>`. Protecting the whole hostname can break
frontend API calls and webhooks.

Verification:

```bash
curl -I https://cms.<domain>/admin
curl -I https://api.<domain>/api
```

Expected result:

- `/admin` redirects to Cloudflare Access for unauthenticated users.
- Public API endpoints remain reachable only if they are intended to be public.

## Origin Configuration By Service

### Frontend

Hostname:

```text
www.<domain>
```

Origin:

```text
OCI Load Balancer -> frontend Kubernetes service
```

Cloudflare behavior:

- Proxied DNS.
- Full (strict) TLS.
- Cache Next.js static assets.
- Bypass cache for dynamic HTML unless the frontend sets explicit cache headers.

### CMS

Hostname:

```text
cms.<domain>
```

Origin:

```text
OCI Load Balancer -> Strapi Kubernetes service
```

Cloudflare behavior:

- Proxied DNS.
- Full (strict) TLS.
- Cloudflare Access on `/admin/*`.
- Bypass cache for `/admin/*` and `/api/*`.
- WAF managed rules enabled.

### API

Hostname:

```text
api.<domain>
```

Origin:

```text
OCI Load Balancer -> Strapi Kubernetes service
```

Cloudflare behavior:

- Proxied DNS.
- Full (strict) TLS.
- Bypass cache by default.
- Add selective API caching only after response headers and invalidation
  behavior are documented.

### IIIF

Hostname:

```text
iiif.<domain>
```

Origin:

```text
OCI Load Balancer -> Cantaloupe Kubernetes service
```

Cloudflare behavior:

- Proxied DNS.
- Full (strict) TLS.
- Cache `GET` and `HEAD` image/tile requests.
- Preserve query strings in cache keys.
- Rate limit carefully because IIIF viewers request many tiles.

## Purging Cache

Purge Cloudflare cache after:

- Replacing a source IIIF image while keeping the same identifier.
- Changing frontend static asset cache policy.
- Correcting an accidentally cached Strapi API response.

Prefer targeted purge by URL or prefix. Avoid full-zone purges unless the
incident scope is unclear.

Examples:

```text
https://iiif.<domain>/iiif/2/<object-id>/*
https://www.<domain>/_next/static/*
```

## Change Management

All Cloudflare configuration changes must be reflected in this repository.

For manual dashboard changes:

1. Record the change in this document.
2. Add Terraform or other IaC when Cloudflare automation is introduced.
3. Include the reason, affected hostnames, and rollback plan in the commit or
   pull request.

For future Terraform work, manage at least:

- DNS records.
- SSL/TLS settings where provider support allows.
- Cache rules.
- WAF custom rules.
- Access applications and policies.

## Troubleshooting

### DNS resolves but HTTPS fails

Check:

- Cloudflare SSL/TLS mode is `Full (strict)`.
- OCI Load Balancer has a certificate covering the hostname.
- The load balancer listener accepts HTTPS on `443`.
- Kubernetes ingress routes the hostname to the correct service.

### Cloudflare returns 521, 522, or 525

Check:

- OCI Load Balancer health checks.
- OKE service endpoints.
- Origin certificate validity.
- Security lists and NSGs between Cloudflare, the load balancer, and OKE nodes.
- Whether the load balancer is accidentally restricted to stale Cloudflare IP
  ranges.

### Strapi admin loops or fails login

Check:

- Cloudflare Access policy allows the user.
- Strapi receives `X-Forwarded-Proto: https`.
- Strapi public URL configuration matches `https://cms.<domain>`.
- Cache bypass rule for `/admin/*` is active.

### IIIF viewer loads slowly or partially

Check:

- Cache rule for `iiif.<domain>` is active.
- Cantaloupe origin health and object storage access.
- WAF or rate limiting is not challenging normal tile requests.
- Query strings are included in the IIIF cache key.

## Definition Of Done

Cloudflare setup is complete when:

- `www`, `cms`, `api`, and `iiif` DNS records are proxied and healthy.
- SSL/TLS uses Full (strict) with valid origin certificates.
- Cache rules bypass Strapi admin/API paths and cache frontend/IIIF assets.
- WAF managed rules and documented custom rules are enabled.
- Cloudflare Access protects `cms.<domain>/admin/*`.
- OCI Load Balancer routes every hostname to the correct OKE service.
- This document matches the live Cloudflare dashboard configuration.
