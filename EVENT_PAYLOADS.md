# Event payload inventory

## Rule

An indexer that sees every event of these packages, plus the transaction
envelope, can build and keep current its index of every party field they
manage without reading object storage or making an RPC call:

- **Set** events carry the full new value (bios, CTA lists, link payloads).
- **Add/remove** events carry the full entry (tag, `ArtistRole`, genre ID and
  name).
- **Clear/remove-field** events carry only the key (`party_id`, and the `Data`
  type argument for platform links); the indexer already holds the old value.
- Equal-value replacements and absent clears emit nothing; a first attachment,
  including an explicitly empty value, emits.
- One event per action. IDs use `ID`; enums are emitted as values, never
  numeric codes. Sender, digest and checkpoint data stay in the envelope.

There is no byte cap beyond Sui's 250 KiB per-event limit; every bound below
is far under it.

## All declared events

| Package | Event | Fields (declaration order) |
|---|---|---|
| `lib/platform_link` | `PlatformLinkSetEvent<Data>` | `parent_id: ID`, `data: Data` |
| `lib/platform_link` | `PlatformLinkRemovedEvent<phantom Data>` | `parent_id: ID` |
| `party_cta` | `CtasSetEvent` | `party_id: ID`, `ctas: vector<Cta>` |
| `party_cta` | `CtasClearedEvent` | `party_id: ID` |
| `party_genre` | `GenreAddedEvent` | `party_id: ID`, `genre_id: ID`, `genre_name: String` |
| `party_genre` | `GenreRemovedEvent` | `party_id: ID`, `genre_id: ID` |
| `party_genre` | `GenresClearedEvent` | `party_id: ID` |
| `party_media` | `MediaSetEvent` | `party_id: ID`, `quilt: u256` |
| `party_media` | `MediaClearedEvent` | `party_id: ID` |
| `party_profile` | `PartyProfileSetEvent` | `party_id: ID`, `bio_short: String`, `bio_long: Option<String>`, `country: Option<CountryCode>`, `languages: vector<LanguageCode>` |
| `party_profile` | `PartyProfileClearedEvent` | `party_id: ID` |
| `party_roles` | `RoleAddedEvent` | `party_id: ID`, `role: ArtistRole` |
| `party_roles` | `RoleRemovedEvent` | `party_id: ID`, `role: ArtistRole` |
| `party_roles` | `RolesClearedEvent` | `party_id: ID` |
| `party_tags` | `TagAddedEvent` | `party_id: ID`, `tag: String` |
| `party_tags` | `TagRemovedEvent` | `party_id: ID`, `tag: String` |
| `party_tags` | `TagsClearedEvent` | `party_id: ID` |

`party_platform_link` declares no events: its writes delegate to
`platform_link`, whose events carry the party's ID as `parent_id`. The pure
payload packages `party_social`, `party_music` and `party_pro_link` declare
and emit none. There are 17 declarations, all emitted.

## Derived values

- Set sizes and `has_*` flags follow from the add/remove/clear stream.
- An `ArtistRole` display name is the fixed variant mapping in
  `party_roles::role_name` (`Dj` → `DJ`); `Custom` carries its own name.

## BCS payload bounds

Serialized payload bytes (type tags excluded). An `ID` or `u256` is 32 bytes;
strings and vectors carry a ULEB128 length; `Option` has a one-byte prefix.

| Event | Maximum bytes | Derivation |
|---|---:|---|
| `PlatformLinkSetEvent<Data>` | 2,034 | `32 + BCS(Data)`; party payloads hold one string of ≤256 B (handle/id: 290) or ≤2,000 B (URL: `32 + 2 + 2000`) |
| `PlatformLinkRemovedEvent<Data>` | 32 | parent ID |
| `CtasSetEvent` | 41,293 | `32 + 1 + 20 × ((1 + 60) + (2 + 2000))`; 33 when empty |
| `CtasClearedEvent` | 32 | party ID |
| `GenreAddedEvent` | 129 | `64 + 1 + 64` (genre names ≤64 B) |
| `GenreRemovedEvent` | 64 | two IDs |
| `GenresClearedEvent` | 32 | party ID |
| `MediaSetEvent` | 64 | ID + `u256` |
| `MediaClearedEvent` | 32 | party ID |
| `PartyProfileSetEvent` | 8,564 | `32 + (2 + 300) + (1 + 2 + 8192) + (1 + 1 + 2) + (1 + 10 × 3)` |
| `PartyProfileClearedEvent` | 32 | party ID |
| `RoleAddedEvent`, `RoleRemovedEvent` | 94 | `32 + 1` variant `+ 1 + 60` for `Custom`; 33 for canonical roles |
| `RolesClearedEvent` | 32 | party ID |
| `TagAddedEvent`, `TagRemovedEvent` | 83 | `32 + 1 + 50` |
| `TagsClearedEvent` | 32 | party ID |

Tests serialize the maximum-content events and assert these sizes.
