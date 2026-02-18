# Dopo Cross-Platform Operations Guide

## How Web + Mobile Stay In Sync

This document is the single source of truth for how Dopo keeps its iOS app, web app, and (future) Android app aligned. Every developer, designer, or AI assistant working on Dopo should read this before making changes.

---

## Architecture Overview

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   iOS App    │     │   Web App   │     │ Android App │
│  (SwiftUI)   │     │  (HTML/JS)  │     │  (Future)   │
└──────┬───────┘     └──────┬──────┘     └──────┬──────┘
       │                    │                    │
       │   x-platform: ios  │  x-platform: web   │  x-platform: android
       │   x-app-version    │  x-app-version     │  x-app-version
       │                    │                    │
       └────────────────────┼────────────────────┘
                            │
                   ┌────────▼────────┐
                   │  Supabase Edge  │
                   │   Functions     │
                   │  (shared API)   │
                   └────────┬────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
     ┌────────▼──┐  ┌──────▼─────┐  ┌───▼────────┐
     │ PostgreSQL │  │  Supabase  │  │  Supabase  │
     │ + pgvector │  │    Auth    │  │  Storage   │
     └────────────┘  └────────────┘  └────────────┘
```

## Rule #1: Business Logic Lives in Edge Functions, NEVER in Clients

Both platforms call the same edge functions. If you need to change how something works (search ranking, ingest processing, permission checks), change it in the edge function. Both clients inherit the change automatically.

**Current Edge Functions:**

| Function | Purpose | Called By |
|----------|---------|----------|
| `config` | Feature flags, design tokens, version checks | iOS, Web |
| `library` | CRUD for saves + collections + collaborators | iOS, Web |
| `ingest` | URL parsing + metadata enrichment | iOS, Web |
| `ai-enrich` | Gemini AI tags + embeddings | Backend (triggered by ingest) |
| `smart-search` | Semantic vector search + NLP | iOS, Web |

---

## Feature Flags System

Every new feature MUST have a feature flag before it ships. This is non-negotiable.

### How It Works

The `feature_flags` table in Supabase controls what's enabled per platform:

```sql
-- Check current flags
SELECT key, enabled_ios, enabled_web, enabled_android FROM feature_flags;
```

### The Config Endpoint

Both clients call `GET /functions/v1/config` on app startup with these headers:

```
x-platform: ios|web|android
x-app-version: 1.0.0
```

Response:
```json
{
  "platform": "ios",
  "force_update": false,
  "minimum_version": "1.0.0",
  "features": {
    "smart_search": { "enabled": true, "rollout": 0 },
    "collections": { "enabled": true, "rollout": 0 },
    "batch_enrichment": { "enabled": true, "rollout": 0 }
  },
  "design_tokens": { ... },
  "api_version": { "current": "v1" }
}
```

### Adding a New Feature Flag

```sql
INSERT INTO feature_flags (key, description, enabled_ios, enabled_web) VALUES
  ('new_feature_key', 'Description of what this feature does', false, false);
```

Then flip `enabled_ios` or `enabled_web` to `true` when each platform is ready.

### Rollout Strategy

1. Ship feature with flag set to `false` on both platforms
2. Enable on web first (instant deploy, easy rollback)
3. Verify on web for 24-48 hours
4. Enable on iOS (App Store delay means rollback takes 1-3 days)
5. Monitor for 1 week before considering the flag permanent

---

## Design Tokens (Single Source of Truth)

Design tokens are stored in `app_config` table under the key `design_tokens`. Both platforms fetch these on startup via the `/config` endpoint.

**Current tokens include:** colors, platformColors, typography, spacing

### When Changing Design

1. Update the `design_tokens` value in `app_config` table
2. Both platforms pick up changes on next app launch
3. For iOS: Also update `Theme.swift` to match (until we implement dynamic theming)
4. For Web: Also update CSS variables in `index.html` (until we implement dynamic theming)

**Future goal:** Both clients should dynamically apply tokens from the config endpoint so design changes propagate without code deploys.

---

## API Versioning

The `app_config` table tracks API versions:

```json
{
  "current": "v1",
  "minimum_supported": "v1",
  "deprecated": []
}
```

### When Changing API Response Shapes

1. Add the new field alongside old fields (additive change = no version bump needed)
2. If removing or renaming a field, create a new version
3. Update the edge function to handle both versions based on a header or query param
4. Update `minimum_supported` only after all active clients have migrated

### Minimum Version Enforcement

The `/config` endpoint returns `force_update: true` if the client's version is below minimum. Use this to show an "Update Required" screen in the app.

---

## The Feature Checklist (Use This for EVERY Change)

Before any feature, bugfix, or design change is considered "done":

### Backend Changes
- [ ] Edge function updated and deployed
- [ ] Database migration applied (if schema change)
- [ ] Feature flag created (if new feature)
- [ ] API response shape is backward-compatible (or versioned)

### iOS Changes
- [ ] Feature flag check implemented in code
- [ ] API client updated to handle new/changed endpoints
- [ ] Design matches shared tokens
- [ ] Tested on simulator AND device
- [ ] TestFlight build submitted

### Web Changes
- [ ] Feature flag check implemented in code
- [ ] API client updated to handle new/changed endpoints
- [ ] Design matches shared tokens
- [ ] Tested in Chrome, Safari, Firefox
- [ ] Deployed to Vercel

### Cross-Platform Verification
- [ ] Both platforms produce identical results from the same API calls
- [ ] Feature flag correctly gates the feature per platform
- [ ] Error states handled consistently
- [ ] Loading states exist on both platforms
- [ ] Empty states exist on both platforms

---

## Known Platform Gaps (Track These)

Features that exist on one platform but not the other:

| Feature | iOS | Web | Notes |
|---------|-----|-----|-------|
| Smart Search | Yes | Yes | Both use same edge function |
| Collections | Yes | Yes | |
| Collection Sharing | Yes | Yes | |
| Batch Enrichment | Yes | No | Flag: batch_enrichment |
| Collection Descriptions | Yes | No | Flag: collection_descriptions |
| Save Detail View | Yes | No | Web has no detail/player view |
| Profile/Settings | Yes | No | Web shows minimal user badge |
| Haptic Feedback | Yes | N/A | iOS only, not applicable |
| Offline Support | No | No | Future consideration |

---

## Security Notes

**Current issues to address:**
1. All edge functions have `verify_jwt: false` — should be `true` for production
2. iOS stores auth tokens in UserDefaults — should use Keychain
3. Supabase anon key is hardcoded in Config.swift — acceptable for client-side key, but keep service role key strictly server-side

---

## Deployment Workflow

```
Feature Branch → Test Locally → Deploy Backend → Deploy Web → Deploy iOS

Web: git push → Vercel auto-deploys (seconds)
iOS: Xcode → Archive → TestFlight (1-3 day review)
Backend: Supabase CLI or Dashboard (instant)
```

**Because iOS deploys are slow, always:**
1. Deploy backend changes first
2. Make backend backward-compatible
3. Use feature flags to gate new client features
4. Never remove an API field until all clients have migrated

---

## Database Tables Reference

| Table | Purpose | RLS |
|-------|---------|-----|
| profiles | User accounts | Yes |
| saves | Saved content | Yes |
| collections | User collections | Yes |
| collection_saves | Collection-save junction | Yes |
| collection_collaborators | Sharing/roles | Yes |
| waitlist | Landing page signups | Yes |
| feature_flags | Per-platform feature toggles | Yes (read-only) |
| app_config | Design tokens, API versions, settings | Yes (read-only) |
