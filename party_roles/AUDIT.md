# Security Audit — `party_roles`
Audited at `067a532492f3db79a100883e994f54731cacc719` (2026-10-21). Scope: `party_roles`, module `party_roles::party_roles`. Later commits only apply naming and ordering standards; line references are to the current code.

## What it does
Stores up to 12 `ArtistRole` values (8 canonical variants plus `Custom(String)`) per party in a `typed_set` under `RolesKey`. See [README](README.md).

## Trust model
- Writes call `party.uid_mut(cap)`, which asserts `cap.party_id == object::id(party)` (`miso_party::party`, `EUnauthorized` = 0) before any mutation or event. Views are permissionless.
- `PartyAdminCap` (`key + store`) is unique per party and transferable. Whoever holds it, or borrows it from a wrapper, controls this slice. Group membership (`is_member`) grants nothing here.
- `ArtistRole::Custom` can be built only through `custom` (`party_roles.move:75-79`), which enforces 1–60 bytes. `RolesKey` has no public constructor.

## Findings
None at Low or above.

**ROL-1 — Info — Accepted.** Equality covers the whole enum value, so `Custom("Artist")` and `Artist` can be held together, and `Custom` names are case-sensitive. The README documents this. Clients render `name` (`:116-128`) as untrusted input.

## Checked, no finding
- `add_role` (`:81-85`): the cap is checked first, then `typed_set` aborts `EDuplicateItem` (0) and then `EMaxItemsExceeded` (2) at 12.
- `remove_role` (`:87-91`) aborts `EItemNotPresent` (1) and drops the field after the last removal.
- `clear_roles` (`:93-100`) emits only when present.
- Events carry the full `ArtistRole` as an enum value; the maximum is 94 bytes (`tests/party_roles_tests.move:268,275`).
- Wrong cap aborts on add, remove and clear.

## Verification
- `sui move test --coverage` (sui 1.82.1): 22/22 pass; module coverage 100.00%.
- Strict lint builds pass for `-e mainnet` and `-e testnet`.
