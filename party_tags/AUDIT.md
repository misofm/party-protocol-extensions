# Security Audit — `party_tags`
Audited at `067a532492f3db79a100883e994f54731cacc719` (2026-10-21). Scope: `party_tags`, module `party_tags::party_tags`.

## What it does
Stores up to 30 free-form tags (1–50 bytes each) per party in a `typed_set` under `TagsKey`. See [README](README.md).

## Trust model
- Writes call `party.uid_mut(cap)`, which asserts `cap.party_id == object::id(party)` (`miso_party::party`, `EUnauthorized` = 0) before any mutation or event. Views are permissionless.
- `PartyAdminCap` (`key + store`) is unique per party and transferable. Whoever holds it, or borrows it from a wrapper, controls this slice. Group membership (`is_member`) grants nothing here.
- `TagsKey` has no public constructor.

## Findings
None at Low or above.

**TAG-1 — Info — Accepted.** `add_tag` checks emptiness and length (`party_tags.move:46-47`) before authorization (`:49`). Dedupe is an exact byte match, with no case folding or trimming. The README documents both.

## Checked, no finding
- `add_tag` (`:45-51`): after the cap check, `typed_set` aborts `EDuplicateItem` (0) and then `EMaxItemsExceeded` (2) at 30.
- `remove_tag` (`:53-57`) aborts `EItemNotPresent` (1) and reclaims the field after the last removal.
- `clear_tags` (`:59-66`) emits only when present.
- Events carry the tag; the maximum is 83 bytes (`tests/party_tags_tests.move:220`).
- Wrong cap aborts on add, remove and clear.

## Verification
- `sui move test --coverage` (sui 1.82.1): 23/23 pass; module coverage 100.00%.
- Strict lint builds pass for `-e mainnet` and `-e testnet`.
