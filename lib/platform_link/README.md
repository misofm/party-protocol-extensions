# platform_link

`PlatformLink<Data>` — a typed link to an entity on one external platform (a
streaming service, a social network, any site), stored as a dynamic field on
any object's `UID`. Protocol-agnostic by design: it knows nothing about
platforms or consumers, so anything in the ecosystem can depend on it.
Consumers never re-implement link storage — they define a `Data` payload type
and get one independent link field per platform, keyed by type. Every actual
change emits a typed event: a set carries the parent ID and the full `Data`
payload, a removal the parent ID, so an indexer never re-reads the field.

URLs are never stored: the client rebuilds the public URL from the `Data` it
reads back, so a platform reshaping its URLs needs no on-chain change.

## What it stores

- Key: `PlatformLinkKey<Data>` (phantom-typed — each platform gets its own
  field on the same `UID`, so adding a platform never touches another's).
- Value: `PlatformLink<Data> { data }` where `Data: copy + drop + store` is
  the platform's native identifier(s) — a handle, id, or subdomain.
- Exactly one link per `Data` type per `UID`; `set` replaces in place.
- `set` emits `PlatformLinkSetEvent<Data>` for inserts and changed replacements;
  equal replacements are silent no-ops. `remove` and `clear` emit
  `PlatformLinkRemovedEvent<Data>` only when a link was present.

The module also owns the shared storage backstops so every payload package
uses the same numbers:

| Function | Value | Applies to |
|---|---|---|
| `max_identifier_length()` | 256 bytes | handles, usernames, ids, subdomains |
| `max_url_length()` | 2000 bytes | payloads whose URL is the identity |

## API

All functions take the host object's `UID` directly; authorization is the
consumer's concern (e.g. `party_platform_link` gates with `PartyAdminCap`).

### Constructor / accessor

| Function | Description |
|---|---|
| `new<Data>(data)` | Wrap a platform payload into a link |
| `data<Data>(&link)` | Read the wrapped payload |

### UID storage

| Function | Description | Aborts |
|---|---|---|
| `set<Data>(&mut uid, link)` | Store, replacing any existing link; emits a set event with the payload when it changes | — |
| `clear<Data>(&mut uid)` | Remove if present and emit a removed event | — (no-op when absent) |
| `remove<Data>(&mut uid)` | Remove and return the link; emits a removed event | `ENoLink` (0) when absent |
| `exists_<Data>(&uid)` | Whether a link is stored | — |
| `get<Data>(&uid)` | `Option<PlatformLink<Data>>` | — |
| `borrow<Data>(&uid)` | `&PlatformLink<Data>` | `ENoLink` (0) when absent |

## Events

| Event | When | Payload |
|---|---|---|
| `PlatformLinkSetEvent<Data>` | `set` on insert or a changed replacement | `parent_id: ID`, `data: Data` (32 + BCS of `Data` bytes) |
| `PlatformLinkRemovedEvent<phantom Data>` | present `remove` or `clear` | `parent_id: ID` (32 bytes); the `Data` type argument is the removed key |

Absent `clear` and equal replacements are silent. The event type argument
identifies the platform. Payload size is bounded by the `Data` type; the party
payload packages cap each string at 256 bytes (identifiers) or 2000 bytes
(URLs), far below Sui's 250 KiB per-event limit.

## Errors

| Code | Constant | Condition |
|---|---|---|
| 0 | `ENoLink` | `borrow` / `remove` with no link stored |

## Dependencies

No explicit manifest dependency. The Sui framework is resolved automatically;
`Move.lock` pins both Testnet and Mainnet framework sources to
`719fb2960ccfbf9f4d33041f8ea5146d30671696`. The manifest has no local-path
or floating dependencies.

## Integrator notes

- Define one `…Data` struct per platform in the appropriate payload package
  (`party_social`, `party_music`, `party_pro_link`), validate non-empty plus
  the shared length backstops in its constructor, and wrap with
  `platform_link::new`.
- Rebuild public URLs client-side from the payload (e.g.
  `x.com/{handle}`) — and treat stored strings as untrusted input when
  rendering.
- `PlatformLinkKey<Data>` types are namespaced by the defining package, so
  identically-named payloads in different packages never collide.
- Index events by their typed event streams: `PlatformLinkSetEvent<Data>`
  carries the new payload, so the field never needs a re-read.
