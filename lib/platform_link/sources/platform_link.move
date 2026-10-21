// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// `PlatformLink<Data>` — a typed link to an entity on one external platform: a
/// streaming service (Spotify, Bandcamp), a social network (X, Instagram), or
/// any other site.
///
/// A protocol-agnostic primitive: it knows nothing about any specific platform,
/// nor about any consumer object (a `Party`, a `Release`, …). It is a generic
/// wrapper around a `Data` payload plus the machinery to store exactly one such
/// link, by type, as a dynamic field on any object's `UID`.
///
/// `Data` is the platform-specific native identifier(s) — an Instagram handle, a
/// Spotify artist id, a Bandcamp subdomain, etc. Each platform defines its own
/// `Data` type in its own small package, so adding a platform is a new type,
/// never a change here. URLs are never stored: a client rebuilds the public URL
/// from the `Data` it reads back, so a platform reshaping its URLs needs no
/// on-chain change.
///
/// Storage is keyed by `PlatformLinkKey<Data>`, whose `phantom Data` makes
/// `PlatformLinkKey<InstagramData>` and `PlatformLinkKey<SpotifyData>` distinct
/// keys — so each platform occupies its own independent field on the same `UID`,
/// and a new platform can be added to a record without touching the others.
module platform_link::platform_link;

use sui::dynamic_field as df;
use sui::event::emit;

// === Errors ===

/// No `PlatformLink<Data>` is stored under this `UID`.
const ENoLink: u64 = 0;

// === Shared limits ===
//
// Owned here so every payload package backstops storage by the same numbers
// and they can never drift. Both are generous storage-hygiene backstops, not
// format validation — real identifiers and URLs are far shorter, and format
// rules change over time and belong in the app layer. (Functions, not
// constants: this toolchain has no `public const`.)

/// Maximum length of a platform identifier — a handle, username, id, or
/// subdomain — in bytes.
public fun max_identifier_length(): u64 { 256 }

/// Maximum length of a stored URL in bytes, for payloads whose URL is the
/// identity (no reconstructable handle).
public fun max_url_length(): u64 { 2000 }

// === Types ===

/// A link to an entity on one platform. `Data` carries that platform's native
/// identifier(s); the public URL is rebuilt from it client-side.
public struct PlatformLink<Data: copy + drop + store> has copy, drop, store {
    data: Data,
}

/// Dynamic-field key for the single `PlatformLink<Data>` on a `UID`. The
/// `phantom Data` gives each platform its own field.
public struct PlatformLinkKey<phantom Data>() has copy, drop, store;

/// Emitted when a platform link is inserted or changed; carries the new payload.
public struct PlatformLinkSetEvent<Data: copy + drop> has copy, drop {
    parent_id: ID,
    data: Data,
}

/// Emitted when a platform link is removed. The phantom `Data` is the key.
public struct PlatformLinkRemovedEvent<phantom Data> has copy, drop {
    parent_id: ID,
}

// === Constructor / accessor ===

/// Wraps a platform-specific payload into a link.
public fun new<Data: copy + drop + store>(data: Data): PlatformLink<Data> {
    PlatformLink { data }
}

/// The wrapped platform-specific payload.
public fun data<Data: copy + drop + store>(self: &PlatformLink<Data>): Data {
    self.data
}

// === UID storage ===
//
// Exactly one `PlatformLink<Data>` per `Data` type per `UID`, keyed by
// `PlatformLinkKey<Data>`. Callers pass the object's `UID` (e.g. a party's, via
// its admin cap), keeping this module free of any object-specific dependency.

/// Whether a `PlatformLink<Data>` is stored under `uid`.
public fun exists_<Data: copy + drop + store>(uid: &UID): bool {
    df::exists(uid, PlatformLinkKey<Data>())
}

/// Sets the `PlatformLink<Data>` under `uid`, replacing any existing one.
/// Emits `PlatformLinkSetEvent<Data>` with the new payload when the value
/// changes; an equal replacement is a no-op.
public fun set<Data: copy + drop + store>(uid: &mut UID, link: PlatformLink<Data>) {
    let data = link.data;
    if (df::exists(uid, PlatformLinkKey<Data>())) {
        let previous: &mut PlatformLink<Data> = df::borrow_mut(uid, PlatformLinkKey<Data>());
        if (previous.data == data) return;
        *previous = link;
    } else {
        df::add(uid, PlatformLinkKey<Data>(), link);
    };
    emit(PlatformLinkSetEvent<Data> { parent_id: uid.to_inner(), data });
}

/// The stored `PlatformLink<Data>`, or `none` if absent.
public fun get<Data: copy + drop + store>(uid: &UID): Option<PlatformLink<Data>> {
    if (df::exists(uid, PlatformLinkKey<Data>())) {
        option::some(*df::borrow(uid, PlatformLinkKey<Data>()))
    } else {
        option::none()
    }
}

/// Borrows the stored link. Aborts if none is stored.
public fun borrow<Data: copy + drop + store>(uid: &UID): &PlatformLink<Data> {
    assert!(df::exists(uid, PlatformLinkKey<Data>()), ENoLink);
    df::borrow(uid, PlatformLinkKey<Data>())
}

/// Removes and returns the stored link. Aborts if none is stored. Emits
/// `PlatformLinkRemovedEvent<Data>`.
public fun remove<Data: copy + drop + store>(uid: &mut UID): PlatformLink<Data> {
    assert!(df::exists(uid, PlatformLinkKey<Data>()), ENoLink);
    let link: PlatformLink<Data> = df::remove(uid, PlatformLinkKey<Data>());
    emit(PlatformLinkRemovedEvent<Data> { parent_id: uid.to_inner() });
    link
}

/// Removes the stored link if present, discarding it. No-op if absent.
public fun clear<Data: copy + drop + store>(uid: &mut UID) {
    if (df::exists(uid, PlatformLinkKey<Data>())) {
        let _: PlatformLink<Data> = df::remove(uid, PlatformLinkKey<Data>());
        emit(PlatformLinkRemovedEvent<Data> { parent_id: uid.to_inner() });
    }
}

// === Test Functions ===

/// Test-only accessor for every `PlatformLinkSetEvent` field, in declaration order.
#[test_only]
public fun set_event_fields<Data: copy + drop>(event: &PlatformLinkSetEvent<Data>): (ID, Data) {
    (event.parent_id, event.data)
}

/// Test-only accessor for every `PlatformLinkRemovedEvent` field.
#[test_only]
public fun removed_event_fields<Data>(event: &PlatformLinkRemovedEvent<Data>): ID {
    event.parent_id
}
