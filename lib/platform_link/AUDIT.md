# Security Audit — `platform_link`
Audited at `067a532492f3db79a100883e994f54731cacc719` (2026-10-21). Scope: `lib/platform_link`, module `platform_link::platform_link`.

## What it does
Stores at most one `PlatformLink<Data>` per `Data` type as a dynamic field on any caller-supplied `UID`, with set/replace, remove, idempotent clear and views. See [README](README.md).

## Trust model
- No authorization of its own: whoever holds `&mut UID` may `set`, `remove` or `clear`. Host objects (e.g. `Party` via `party::uid_mut(cap)`) gate access.
- `new` (`platform_link.move:36`) wraps any `Data: copy + drop + store` without validation; payload validation belongs to the module that defines `Data` (its fields are private to it).
- `PlatformLinkKey<Data>` has no public constructor, so no other module can read or write the field except through this API.
- Nobody can forge `parent_id`: events take it from the `UID` itself.

## Findings

**PL-1 — Medium — Open.** Both recorded publications of this package (`Published.toml:7` testnet `0xacec…4d8d`, `Published.toml:15` mainnet `0xd438…5609`) predate the current source. Queried on-chain, their `PlatformLinkSetEvent` is `{ parent_id: address, existed_before: bool, exists_after: bool }`: no payload. The current source has `{ parent_id: ID, data: Data }` (`platform_link.move:25-28`). Dependents in this repo use `platform_link = { local = "../lib/platform_link" }`, and the build links them to the recorded `published-at`. A testnet build of `party_music` lists `0xacec…4d8d` as its dependency. The old package exports the same public functions (`new`, `set`, `clear`, `remove`, `get`, `borrow`, `exists_`, `data`, `max_*`), so a dependent publish against it succeeds silently and emits payload-free events. That breaks the event-sufficiency rule for an immutable stack. Fix: republish `platform_link` first and confirm its `Published.toml` block is replaced before any dependent is built. Tooling should check that dependency linkage resolves to the freshly published address.

**PL-2 — Info — Accepted.** `set` and `new` accept any `Data`. The README's backstops (`platform_link.move:89,91`) are numbers for payload packages to use, not checks here. A host-authorized caller can attach an arbitrary type, including an unbounded value up to Sui's object and event limits (a 100,000-byte payload was accepted in a probe). Event-size bounds in `EVENT_PAYLOADS.md` hold only for the three party payload packages.

**PL-3 — Info — Accepted.** `borrow` (`platform_link.move:84`) returns a reference, so it cannot be called from a PTB or a dev-inspect. Off-chain readers use `get` or read the field object.

**PL-4 — Info — Open.** The root README (Conventions) and AGENTS.md say committed manifests contain no local-path dependency. Four manifests do have one: `party_music`, `party_social`, `party_pro_link` and `party_platform_link` use `platform_link = { local = "../lib/platform_link" }`, and `party_platform_link` also has a test-only `party_social`. The root README also says every `Published.toml` records a prior Testnet generation, but each one also records a mainnet block whose bytecode predates the current source (PL-1). Fix: correct both statements.

## Checked, no finding
- Key namespacing: `PlatformLinkKey<phantom Data>` (`:21`) is unique per fully qualified `Data` type, so payloads with the same name in different packages never collide.
- `set` (`:40-50`) inserts or replaces in place, returns early without an event on an equal value (`:44`), and emits exactly one set event otherwise.
- `remove` (`:52-57`) aborts `ENoLink` (0) when absent; `clear` (`:59-64`) is silent when absent; both emit one removed event when present.
- No funds, no objects created, no `key` types; all values have `copy + drop`, so nothing can get stuck.
- Errors: a single `u64` constant, reachable only through `remove` or `borrow`.

## Operational requirements
- Republish this package before its dependents (PL-1).
- Indexers must whitelist the `Data` types (by defining package) they treat as party links. The event type is `platform_link::PlatformLinkSetEvent<Data>` for every host object, so `parent_id` may also be a non-`Party` object.

## Verification
- `sui move test --coverage` (sui 1.82.1): 9/9 pass; module coverage 100.00%.
- Strict lint builds (`--lint --warnings-are-errors`) pass for `-e mainnet` and `-e testnet`.
- Probes (not committed) covered an unvalidated arbitrary `Data` and direct `remove` via a `Party` UID. On-chain struct and function layouts of both recorded publications were checked through GraphQL.
