# Dopo — Project Status & Plan
### Updated: February 16, 2026

---

## Executive Summary

Dopo is a social curation platform for saved social media content — "Pinterest for your social media saves." Users save content from Instagram, TikTok, YouTube, X, and Facebook into one searchable, AI-enriched library. The strategic differentiator is the social discovery layer (public collections, follow graph, collaborative curation) that no competitor has built.

**Model:** Claude as CTO + iOS Contractor Execution
**Stack:** Native iOS (Swift/SwiftUI) + Supabase Backend + AI Pipeline
**Domain:** dopoapp.com
**Demo:** dopo-demo.vercel.app
**Landing Page:** dopoapp.com (live, waitlist active)

---

## What's Done

### Infrastructure (Complete)
- [x] Supabase project deployed (PostgreSQL, Auth, Edge Functions, Storage)
- [x] Database schema: profiles, saves, collections, collection_saves, waitlist
- [x] Row Level Security policies on all tables
- [x] Full-text search with weighted tsvector (title=A, description=B, tags=B, notes=C)
- [x] Auto-updating search vectors via trigger on INSERT/UPDATE
- [x] Two user accounts created and functional
- [x] Waitlist table with name field support

### Ingest Pipeline (Complete — v10)
- [x] `ingest` edge function (v10) — URL parsing for YouTube, Instagram, TikTok, X/Twitter, Facebook
- [x] YouTube enrichment via oEmbed API (title, thumbnail, creator)
- [x] Instagram/TikTok enrichment via Microlink API (captions, thumbnails, hashtags)
- [x] X/Twitter enrichment via oEmbed + Microlink fallback
- [x] Facebook URL parsing (reels, videos, stories, marketplace, posts)
- [x] Share text fallback enrichment for creator handles
- [x] Duplicate detection via canonical URL matching
- [x] Auto-triggers ai-enrich on every save (fire-and-forget)

### Library API (Complete — v9)
- [x] `library` edge function (v9) — GET (list/search), DELETE, PATCH (favorite/note/tags)
- [x] Full-text search via `search_saves` RPC with platform/content-type filtering
- [x] Fuzzy ILIKE fallback when full-text returns zero results
- [x] Pagination support (limit/offset)
- [x] Collections CRUD — create, list, add/remove saves, rename, delete
- [x] Collection filtering — list saves by collection
- [x] Collection membership returned with each save
- [x] Share collections — toggle public/private, generate shareable link
- [x] Public shared view — unauthenticated read-only collection viewing via share_token
- [x] Collaborator management — invite by email, auto-accept existing users, remove collaborators
- [x] Collaborator access — editors can add/remove saves from shared collections
- [x] Cross-user collection viewing — collaborators see owner's saves in shared collections
- [x] View-only vs Editor roles — role selector on invite, role badges, role switching, UI enforcement

### AI Metadata Extraction (Complete — v7)
- [x] `ai-enrich` edge function (v7) with Gemini 2.0 Flash integration
- [x] Rule-based fallback when Gemini unavailable
- [x] Single save, batch, force re-enrich, and debug modes
- [x] 18 content categories supported
- [x] All 25 saves enriched with AI tags and categories
- [x] GEMINI_API_KEY configured in Supabase secrets

### Web Demo Prototype (Complete)
- [x] Single-page HTML app with auth, ingest, search, and card-based library
- [x] 32 saves across 4 platforms (YouTube, Instagram, Facebook, X — TikTok parser ready)
- [x] Platform filter buttons for all 5 platforms
- [x] Bulk import (paste multiple URLs)
- [x] Sign out functionality
- [x] Branded platform fallback placeholders when thumbnails fail
- [x] Collections UI — create, delete, filter by collection, add/remove saves
- [x] Share & Collaborate UI — public toggle, shareable link with copy, collaborator invite/remove
- [x] Shared collection view — public read-only page for anyone with the link
- [x] Visual indicators on collection chips (🔗 public, ✏️ editor, 👁️ viewer)
- [x] Role-based UI enforcement — viewers see notice bar, can't add saves or manage collection
- [x] Deployed to Vercel: dopo-demo.vercel.app
- [x] GitHub repo: legacyaisolutions/dopo-demo (push access configured)

### Landing Page (Complete)
- [x] dopo-site deployed to Vercel: dopoapp.com
- [x] Waitlist form with name + email fields
- [x] Connected to Supabase waitlist table
- [x] SVG platform logos
- [x] GitHub repo: legacyaisolutions/Dopo-site

### Business/Brand
- [x] Domain: dopoapp.com registered and pointing to landing page
- [x] 26-page technical architecture document (contractor operating manual)
- [x] Competitive research v2 (Ordo + Saver teardowns, Option B social strategy)
- [x] Positioning: "Pinterest for your social media saves"
- [ ] Social handles (@dopo or @getdopo) — not yet registered
- [x] Patent filing guide — step-by-step .docx created (Dopo_Patent_Filing_Guide.docx)
- [ ] Patent application — pending filing (guide ready, NateDawg's task)

---

## Current Database State

| Table | Rows | Notes |
|-------|------|-------|
| saves | 32 | 6 YouTube, 11 Instagram, 12 Facebook, 3 X/Twitter, 0 TikTok |
| profiles | 3 | nate-demo@dopo.app, lesaraskog@gmail.com, adaraskog@gmail.com |
| collections | 2 | Active collections with saves assigned |
| collection_saves | 13 | Saves organized into collections |
| collection_collaborators | 2 | Cross-user sharing active and tested |
| waitlist | 2 | Both signed up before name field was added |

---

## Edge Functions Registry

| Function | Version | Purpose | Status |
|----------|---------|---------|--------|
| `ingest` | v10 | URL parsing + metadata enrichment + auto-enrich trigger | ACTIVE |
| `library` | v10 | CRUD + search + collections + sharing + collaborators + cross-user collection saves | ACTIVE |
| `ai-enrich` | v7 | Gemini AI tag generation + categorization | ACTIVE |
| `upload-demo` | v1 | Utility for pushing HTML to Supabase storage | ACTIVE |
| `demo` | v6 | (Deprecated — Vercel hosts demo now) | ACTIVE |

---

## Known Issues

| Issue | Severity | Notes |
|-------|----------|-------|
| Facebook saves often show "Log into Facebook" as title | Medium | Microlink hits Facebook's login wall; metadata extraction limited |
| No TikTok saves in DB | Low | Parser works, just no test content ingested yet |
| Leaked password protection disabled | Low | Requires Supabase Pro plan; not worth upgrading yet |
| Waitlist RLS policy is INSERT WITH CHECK (true) | Low | Intentional for public waitlist; acceptable |
| No email notifications for collaborator invites | Low | Needs transactional email service (Resend/SendGrid) |
| Shared view URL uses query param | Low | `?shared=TOKEN` works but `/c/:token` route cleaner for production |

---

## What's Next

### ✅ Recently Completed (Feb 15-16)
- ~~Collections UI in web demo~~ → DONE — full CRUD, filtering, add-to-collection
- ~~Share Collection~~ → DONE — public toggle, shareable links, read-only shared view
- ~~Collaborative collections~~ → DONE — invite by email, editor role, cross-user saves
- ~~Patent filing guide~~ → DONE — comprehensive .docx with step-by-step USPTO process
- ~~Third demo account~~ → DONE — adaraskog@gmail.com with collaboration tested

### Immediate Priority
1. **Add TikTok test saves** — demonstrate 5-platform coverage (parser is ready, no test data)
2. **Fix Facebook enrichment** — consider alternative metadata sources or manual title override
3. **Delete save functionality** in demo UI — API already supports DELETE, needs a button
4. **Demo polish** — mobile responsive tweaks, loading skeletons, better error handling
5. **Register social handles** (@dopo / @getdopo on X, Instagram, TikTok)

### Next Phase (Weeks 2-3)
6. **User profiles page** — public profile with collections grid, bio, save count
7. **Follow graph** — follow users, discovery feed of public collections
8. **Notification system** — collaborator invites, new saves in shared collections
9. **Transactional email** — invite notifications via Resend or SendGrid
10. **Contractor job posting** — leverage live demo (now with sharing!) + architecture doc

### Phase 0 Gate (Requires iOS Contractor)
11. **iOS Share Extension POC** — Instagram + YouTube capture via share sheet
12. **Basic iOS app shell** — SwiftUI with Supabase auth + library display
13. **TestFlight deployment** for personal testing

### Production Readiness
14. **Dedicated share routes** — `/c/:token` instead of `?shared=token`
15. **Rate limiting** on ingest and API endpoints
16. **Image proxy/CDN** for thumbnails (reliability + privacy)
17. **Supabase Pro upgrade** — leaked password protection, higher limits
18. **File provisional patent** — guide ready, needs execution

---

## Architecture Overview

```
User → iOS Share Sheet → Dopo Share Extension
                              ↓
                        Supabase Edge Functions
                        ├── ingest v10 (URL parse + enrich + auto-AI)
                        ├── ai-enrich v7 (Gemini AI tags/categories)
                        ├── library v9 (CRUD + search + collections + sharing + collab)
                        └── [future: follow graph + notifications]
                              ↓
                        PostgreSQL (Supabase)
                        ├── saves (with search_vector, ai_tags, category)
                        ├── profiles
                        ├── collections (is_public, share_token, description)
                        ├── collection_saves
                        ├── collection_collaborators (role, accepted, invited_email)
                        └── waitlist
```

## Key Credentials & URLs

| Resource | Value |
|----------|-------|
| Supabase Project | adyqktvkxwohzxzjqpjt |
| Supabase Org | LegacyAi Solutions (Free plan) |
| API URL | https://adyqktvkxwohzxzjqpjt.supabase.co |
| Demo URL | https://dopo-demo.vercel.app |
| Landing Page | https://dopoapp.com |
| GitHub Demo Repo | legacyaisolutions/dopo-demo |
| GitHub Site Repo | legacyaisolutions/Dopo-site |
| Vercel Team | nates-projects-1c1ff6ae |
| Demo Account 1 | nate-demo@dopo.app / dopo-prototype-2026 |
| Demo Account 2 | lesaraskog@gmail.com |
| Demo Account 3 | adaraskog@gmail.com / NateDrew$08 |

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| Jan 15 | Supabase over Firebase | Better SQL querying for search features |
| Jan 15 | Native Swift over React Native | Share extensions are first-class in native |
| Jan 15 | AI-native from day 1 | Core differentiator; compress development 50% |
| Feb 12 | YouTube + Instagram first | YouTube = cleanest URLs, Instagram = highest demand |
| Feb 12 | Claude as CTO model | Non-technical founder; AI handles architecture |
| Feb 13 | Gemini 2.0 Flash for dev | Free tier sufficient for prototype |
| Feb 14 | Vercel for demo hosting | Supabase blocks HTML serving in edge functions |
| Feb 14 | Rule-based + AI hybrid | Fallback enrichment when API unavailable |
| Feb 15 | Option B: Social curation | Private utility = dead (Pocket). Social = platform (Pinterest) |
| Feb 15 | Collaborative collections | 5th retention loop; group obligation mechanic |
| Feb 16 | Collections UI + Share/Collab shipped same day | Backend was ready; front-end build validated full stack |
| Feb 16 | Auto-accept collaborator invites for existing users | Simpler for demo; pending invites stored for future signups |
| Feb 16 | Share token on query param for MVP | `?shared=TOKEN` avoids routing complexity; clean URL in production |

---

## Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| iOS Share Extension unreliable | Fatal | Medium | Phase 0 gate; contractor must have share extension experience |
| Microlink API rate limits (50/day free) | High | High | Paid plan ($50/mo) or switch to direct scraping |
| Facebook metadata extraction limited | Medium | High | Login wall blocks enrichment; consider oEmbed or manual override |
| Contractor hiring delay | High | Medium | Live demo + architecture doc reduce friction |
| Platform API changes | Medium | High | Cache metadata at save time; build value on curation layer |
| Patent timeline | Low | Low | File provisional ASAP for priority date |
| No technical co-founder | High | High | Use live demo + sharing data to recruit |

---

*Last updated by Claude — February 16, 2026*
