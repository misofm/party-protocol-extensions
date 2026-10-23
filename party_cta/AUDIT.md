# Security Audit — `party_cta`
Audited at `067a532492f3db79a100883e994f54731cacc719` (2026-10-21). Scope: `party_cta`, module `party_cta::party_cta`. Later commits only apply naming and ordering standards; line references are to the current code.

## What it does
Stores one ordered `vector<Cta { label, url }>` per party under `CtasKey`, replaced as a whole. See [README](README.md).

## Trust model
- Writes call `party.uid_mut(cap)`, which asserts `cap.party_id == object::id(party)` (`miso_party::party`, `EUnauthorized` = 0) before any mutation or event. Views are permissionless.
- `PartyAdminCap` (`key + store`) is unique per party and transferable. Whoever holds it, or borrows it from a wrapper, controls this slice. Group membership (`is_member`) grants nothing here.
- `Cta` (`copy + drop + store`) can be built only through `new_cta` (`party_cta.move:49-55`), so every stored entry passed its validation. `CtasKey` has no public constructor.

## Findings

**CTA-1 — Info — Accepted.** `set_ctas` checks the list length (`party_cta.move:79`) before authorization (`:81`), so an over-cap list with a wrong cap aborts `ETooManyCtas`, not `EUnauthorized` (probe-verified). The README documents this. No state changes either way.

**CTA-2 — Info — Accepted.** Duplicate entries are allowed, and URLs have no scheme check: `javascript:` URLs are accepted (probe). Clients must sanitize, as the README says.

**CTA-3 — Info — Open.** The README says on-Miso actions "live in `party_featured`". No such package exists; the ROADMAP lists it as Phase 2. Fix: say it is planned.

## Checked, no finding
- Bounds: label 1–60 bytes, URL 1–2000 bytes (`:50-53`), at most 20 entries (`:79`). The largest `CtasSetEvent` is 41,293 bytes, asserted in `tests/party_cta_tests.move:179`, far below the 250 KiB event limit.
- Equal replacement returns before any event (`:84`). A first set emits, including an empty list. `clear_ctas` (`:92-99`) emits only when present.
- Wrong cap aborts on set, replace and clear (absent or present).
- Abort codes 0–4 are plain `u64` constants, all reachable and tested.
- No funds or objects. The field holds `copy + drop` values only and is reclaimed by `clear_ctas`.

## Verification
- `sui move test --coverage` (sui 1.82.1): 18/18 pass; module coverage 100.00%.
- Strict lint builds pass for `-e mainnet` and `-e testnet`.
