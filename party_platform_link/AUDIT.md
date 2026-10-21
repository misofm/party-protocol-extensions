# Security Audit — `party_platform_link`
Audited at `067a532492f3db79a100883e994f54731cacc719` (2026-10-21). Scope: `party_platform_link`, module `party_platform_link::party_platform_link`.

## What it does
Party wiring for `platform_link`: cap-gated `set_link<Data>` / `clear_link<Data>` and permissionless `has_link` / `link` views. See [README](README.md).

## Trust model
- Writes call `party.uid_mut(cap)`, which asserts `cap.party_id == object::id(party)` (`miso_party::party`, `EUnauthorized` = 0) before any mutation or event.
- `PartyAdminCap` (`key + store`) is unique per party and transferable. Whoever holds it, or borrows it from a wrapper, controls every link. Group membership (`is_member`) grants nothing here.
- The cap holder can also call `platform_link::set`/`remove`/`clear` directly on `party.uid_mut(cap)`. That is the same authority, and the same events are emitted.

## Findings

**PPL-1 — Medium — Open.** This package links to `platform_link` through a local path (`Move.toml:9`). That resolves to the recorded `platform_link` publication, whose set event carries no payload (see `lib/platform_link/AUDIT.md` PL-1). Publishing this package before `platform_link` is republished yields link events without the link data. Fix: republish `platform_link` first and verify the dependency address in the build output.

**PPL-2 — Low — Open.** `set_link` (`party_platform_link.move:13-19`) accepts any `Data: copy + drop + store`. `platform_link::new` is public and unvalidated, so a cap holder can attach links of any type (e.g. `String`, `u64`, a custom struct holding 100,000 bytes, all accepted in probes). There is no limit on the number of distinct `Data` fields per party. Harm is limited to the holder's own party, but the README says that payload constructors validate "before a link can exist". That is true only for the `party_social`, `party_music` and `party_pro_link` types. Fix: correct the README and require indexers and clients to whitelist `Data` types by package address.

**PPL-3 — Info — Accepted.** No ownership proof of handles: a party can copy another party's `PlatformLink<XData>` from `link<XData>` (`:34`) or construct the same handle. Verification is off-chain.

**PPL-4 — Info — Accepted.** `clear_link` (`:21-26`) checks `exists_` at `:23`, but `platform_link::clear` already does nothing when absent. The check is redundant; behavior is identical.

**PPL-5 — Info — Accepted.** Writes work on a `Party` that has not been shared yet (between `party::new` and `party::share` in one PTB). Link events can then precede `PartyCreatedEvent` in the same transaction (probe-verified). This applies to every state-attaching package.

## Checked, no finding
- Wrong cap aborts `EUnauthorized` on set (absent, present or equal value) and on clear (absent or present), before any event. Covered by `tests/party_platform_link_auth_tests.move`.
- `ENoLink` is unreachable: only `set`, `clear`, `exists_` and `get` are called.
- Events: one set event per insert or change, none for an equal value; one removed event per present clear, none when absent. `parent_id` is the party ID.
- Distinct `Data` types and distinct parties produce independent fields and event streams.
- `party_social` is a test-only dependency (`modes = ["test"]`, `Move.toml:13`) and is absent from the production graph.

## Operational requirements
- Republish `platform_link` before this package (PPL-1).
- Indexers: filter `PlatformLinkSetEvent<Data>` and `PlatformLinkRemovedEvent<Data>` by whitelisted `Data`, and by `parent_id` against known `Party` IDs. Do not assume that `PartyCreatedEvent` comes first.

## Verification
- `sui move test --coverage` (sui 1.82.1): 9/9 pass; module coverage 100.00%.
- Strict lint builds pass for `-e mainnet` and `-e testnet`. A testnet bytecode dump of a sibling payload package shows `platform_link` linked at `0xacec…4d8d`.
