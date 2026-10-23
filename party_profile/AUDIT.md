# Security Audit — `party_profile`
Audited at `067a532492f3db79a100883e994f54731cacc719` (2026-10-21). Scope: `party_profile`, module `party_profile::party_profile`. Later commits only apply naming and ordering standards; line references are to the current code.

## What it does
Stores one replace-whole `Profile { bio_short, bio_long, country, languages }` per party under `ProfileKey`. See [README](README.md).

## Trust model
- Writes call `party.uid_mut(cap)`, which asserts `cap.party_id == object::id(party)` (`miso_party::party`, `EUnauthorized` = 0) before any mutation or event. Views are permissionless.
- `PartyAdminCap` (`key + store`) is unique per party and transferable. Whoever holds it, or borrows it from a wrapper, controls this slice. Group membership (`is_member`) grants nothing here.
- `Profile` (`store + drop`) can be built only inside `set_profile`. `CountryCode` and `LanguageCode` can be built only through their validating packages.

## Findings
None at Low or above.

**PRO-1 — Info — Accepted.** All validation (`party_profile.move:67-78`) runs before authorization (`:83`), so invalid input with a wrong cap aborts with the validation code. The README documents this.

**PRO-2 — Info — Accepted.** `profile` (`:109-112`) returns `&Profile` and aborts `ENoProfile` (5) when unset. A function that returns a reference cannot be called from a PTB or a dev-inspect, so off-chain readers must read the dynamic field object.

## Checked, no finding
- Bounds: `bio_short` 1–300 bytes (`:67-68`); `bio_long` 1–8192 bytes when present (`:69-72`); at most 10 languages with no duplicates (`:73-78`, O(n²) over n ≤ 10).
- Equal replacement compares the whole card and is silent (`:86`). The event is built from the same values that are stored (`:81-82`).
- `clear_profile` (`:94-101`) emits only when present. The largest set event is 8,564 bytes and is asserted in the tests.
- Wrong cap aborts on set and on clear (absent or present).
- Error codes 0–6 are plain `u64` constants; all are reachable and tested.

## Verification
- `sui move test --coverage` (sui 1.82.1): 23/23 pass; module coverage 100.00%.
- Strict lint builds pass for `-e mainnet` and `-e testnet`.
