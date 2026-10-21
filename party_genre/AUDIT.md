# Security Audit — `party_genre`
Audited at `067a532492f3db79a100883e994f54731cacc719` (2026-10-21). Scope: `party_genre`, module `party_genre::party_genre`.

## What it does
Stores up to 20 `genre::Genre` object IDs per party in a `typed_set` under `GenresKey`. Adding requires a `&Genre`; removal is by ID. See [README](README.md).

## Trust model
- Writes call `party.uid_mut(cap)`, which asserts `cap.party_id == object::id(party)` (`miso_party::party`, `EUnauthorized` = 0) before any mutation or event. Views are permissionless.
- `PartyAdminCap` (`key + store`) is unique per party and transferable. Whoever holds it, or borrows it from a wrapper, controls this slice. Group membership (`is_member`) grants nothing here.
- `GenresKey` has no public constructor, so `typed_set` calls on this key are possible only through this module.
- `Genre` objects are frozen and live at a derived address under the single `GenreRegistry` (`genre::genre::new`), so names and IDs are immutable and unique.

## Findings

**GEN-1 — Info — Accepted.** The vocabulary is open: `genre::genre::new` takes `&mut GenreRegistry` and no cap. Any sender can mint a genre with any `[A-Z_]` name of 1–64 bytes and tag a party with it (probe-verified). "Proven at write time" means only that the `Genre` exists in the registry, not that it was curated. Curation, if wanted, belongs off-chain or in a later catalog object.

## Checked, no finding
- `add_genre` (`party_genre.move:41-46`): `typed_set` aborts `EDuplicateItem` (0) before `EMaxItemsExceeded` (2). The cap is checked first because `uid_mut` is evaluated before the `typed_set` call.
- `remove_genre` (`:48-52`) aborts `EItemNotPresent` (1) when the ID is missing or no set exists. Removing the last item drops the field.
- `clear_genres` (`:54-61`) emits only when a set exists.
- Events: an add carries `genre_id` and the immutable `genre_name` (at most 129 bytes); a remove carries `genre_id`; a clear carries `party_id`. One event per action.
- Wrong cap on add, remove and clear (with or without a set present) aborts `EUnauthorized`.
- Dependencies are exact pins: `miso_party` `8e59a81…`, `typed_set` `b37474c…`, `genre` `4c47bd1…`.

## Verification
- `sui move test --coverage` (sui 1.82.1): 15/15 pass; module coverage 100.00%.
- Strict lint builds pass for `-e mainnet` and `-e testnet`.
