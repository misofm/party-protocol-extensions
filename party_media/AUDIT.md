# Security Audit — `party_media`
Audited at `067a532492f3db79a100883e994f54731cacc719` (2026-10-21). Scope: `party_media`, module `party_media::party_media`.

## What it does
Stores one nonzero Walrus quilt blob ID (`u256`) per party under `MediaKey`. See [README](README.md).

## Trust model
- Writes call `party.uid_mut(cap)`, which asserts `cap.party_id == object::id(party)` (`miso_party::party`, `EUnauthorized` = 0) before any mutation or event. Views are permissionless.
- `PartyAdminCap` (`key + store`) is unique per party and transferable. Whoever holds it, or borrows it from a wrapper, controls this slice. Group membership (`is_member`) grants nothing here.
- `Media` (`store + drop`, no `copy`) and `MediaKey` can be created only by this module.

## Findings
None at Low or above.

**MED-1 — Info — Accepted.** `set_media` rejects a zero quilt (`party_media.move:38`) before authorization, so a zero quilt with a wrong cap aborts `EZeroQuilt`. The README documents this. No other format check: any nonzero `u256` is accepted, and it is not checked to be an existing Walrus blob.

## Checked, no finding
- `set_media` (`:37-49`) inserts or replaces in place and is silent on an equal value (`:43`). `clear_media` (`:51-58`) is silent when absent.
- Events: `MediaSetEvent` is 64 bytes and `MediaClearedEvent` 32 bytes (`tests/party_media_tests.move:34,64`).
- Wrong cap aborts on set (absent, present or equal value) and on clear (absent or present).
- `quilt` (`:66-69`) returns `Option`, so the view never aborts.

## Verification
- `sui move test --coverage` (sui 1.82.1): 11/11 pass; module coverage 100.00%.
- Strict lint builds pass for `-e mainnet` and `-e testnet`.
