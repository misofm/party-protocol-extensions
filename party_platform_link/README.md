# party_platform_link

The `Party` wiring for `PlatformLink<Data>`: it attaches one independent
external-platform link per platform type — `set_link<XData>`,
`set_link<SpotifyData>`, … — each in its own dynamic field on the party, keyed
by `Data`. One module serves every platform (social, music, pro) because it is
generic over the payload; the payload types live in their own small packages
(`party_social`, `party_music`, `party_pro_link`), so adding a platform is a
new type there, never a change here — and adding one never rewrites another's.

Storage mechanics come entirely from `platform_link`; this module adds only
the party-specific cap gate and views. Writes are gated by the
`PartyAdminCap` through `party::uid_mut(cap)`; views are permissionless. Events
come from the primitive: each insertion or changed replacement emits the party
ID and the full payload, each present clear the party ID. Equal replacements
and absent clears are silent. This module declares no events of its own.

## What it stores

One dynamic field per platform `Data` type on the party's `UID`, held via
`platform_link`:

- Key: `PlatformLinkKey<Data>` (owned by `platform_link`; its `phantom Data`
  makes each platform's key a distinct type, so fields never collide).
- Value: `PlatformLink<Data> { data }`, where `Data: copy + drop + store` is
  the platform's native identifier(s) — a handle, id, or subdomain — defined
  and validated by a payload package.
- Exactly one link per `Data` type per party: `set_link` replaces in place,
  `clear_link` reclaims the field.

No limits are declared here. Payload constructors validate non-empty plus the
shared backstops (`platform_link::max_identifier_length()` 256 bytes,
`max_url_length()` 2000 bytes) before a link can exist.

## API

All writes require `&PartyAdminCap` for the exact party; a wrong cap aborts
with `EUnauthorized` at `miso_party::party`.

### Writes (cap-gated)

| Function | Description | Aborts |
|---|---|---|
| `set_link<Data>(party, cap, PlatformLink<Data>)` | Store the link, replacing any existing one for that platform; delegates to `platform_link::set`, which emits on insertion or changed replacement | wrong cap |
| `clear_link<Data>(party, cap)` | Remove the platform's link; delegates to `platform_link::clear`, which emits `PlatformLinkRemovedEvent<Data>` only when one was stored, and is silent otherwise | wrong cap — the cap is verified before the existence check, so a wrong cap aborts even when nothing is stored |

### Views

| Function | Returns |
|---|---|
| `has_link<Data>(party)` | `bool` — whether a link for this platform is set |
| `link<Data>(party)` | `Option<PlatformLink<Data>>` — the stored link, if any |

## Events

| Event | When | Payload |
|---|---|---|
| `PlatformLinkSetEvent<Data>` | Insertion or changed replacement; emitted by `platform_link` | `parent_id: ID` (the party), `data: Data` — at most 32 + 2 + 2000 BCS bytes for the party payload types |
| `PlatformLinkRemovedEvent<phantom Data>` | Present `clear_link`; emitted by `platform_link` | `parent_id: ID` (32 bytes) |

The `Data` type argument identifies the platform that changed.

## Errors

| Code | Constant | Condition |
|---|---|---|
| 0 | `EUnauthorized` (at `miso_party::party`) | The cap does not belong to this party — both writes gate through `party::uid_mut(cap)` before any mutation or event |

No error constants are declared in this module, and none surface from
`platform_link`: `set_link` / `clear_link` call only its non-aborting
functions (`set`, `clear`, `exists_`, `get`), so `ENoLink` is unreachable
here. Payload-constructor aborts (empty or oversized identifiers) fire in the
payload packages, before `set_link` is ever called.

## Dependencies

- [`miso_party`](https://github.com/misofm/party-protocol) at exact revision
  `65f22c8a0e8e32ac4ee52322536a15cbb5b0a429` — `Party` authorization. This
  is the manifest's only Git pin.
- [`platform_link`](../lib/platform_link) — a local-path sibling package
  (`platform_link = { local = "../lib/platform_link" }`) — all storage
  mechanics.
- [`party_social`](../party_social) — a local-path sibling package
  (`party_social = { local = "../party_social", modes = ["test"] }`),
  test-only; concrete payloads for generic tests, absent from the
  production dependency graph.

`miso_party` is the manifest's only Git pin; `platform_link` and `party_social`
are local-path dependencies.

## Integrator notes

- **Subscribe per platform.** Filter the primitive events by the `Data` type to
  know which platform changed; the set event carries the new payload.
  `PlatformLinkRemovedEvent` appears only when a link was actually removed;
  absent and repeated clears are silent.
- **URLs are rebuilt, never stored.** The payload carries a handle, id, or
  subdomain; the client constructs the public URL (e.g. `x.com/{handle}`), so
  a platform reshaping its URLs needs no on-chain change.
- **Stored strings are untrusted input.** Sanitize handles before rendering —
  on-chain validation is non-empty plus length backstops, not format or
  safety.
- **One link per platform, by construction.** There is no list to paginate and
  no duplicates to merge; re-setting a platform replaces in place.
- **New platforms don't touch this package.** Define a `…Data` type with a
  validating constructor in the appropriate payload package, and
  `set_link<NewData>` works immediately.
