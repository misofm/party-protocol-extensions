// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// `PlatformLink<Data>`: a typed link to an entity on one external platform (a
/// streaming service, a social network, any other site).
///
/// Protocol-agnostic: it knows no platform and no consumer object. `Data` is the
/// platform's native identifier (a handle, an artist id, a subdomain), defined
/// in its own small package, so adding a platform is a new type, never a change
/// here. URLs are not stored; clients rebuild them from `Data`.
///
/// One link per `Data` type is stored as a dynamic field on any `UID`, keyed by
/// `PlatformLinkKey<Data>`; the phantom `Data` gives each platform its own field.
module platform_link::platform_link;

// === Imports ===

use sui::dynamic_field as df;
use sui::event::emit;

// === Errors ===

/// No `PlatformLink<Data>` is stored under this `UID`.
const ENoLink: u64 = 0;

// === Structs ===

/// A link to an entity on one platform. `Data` carries that platform's native
/// identifier(s); the public URL is rebuilt client-side.
public struct PlatformLink<Data: copy + drop + store> has copy, drop, store {
    data: Data,
}

/// Dynamic-field key for the single `PlatformLink<Data>` on a `UID`. The
/// `phantom Data` gives each platform its own field.
public struct PlatformLinkKey<phantom Data>() has copy, drop, store;

// === Events ===

/// Emitted when a platform link is inserted or changed; carries the new payload.
public struct PlatformLinkSetEvent<Data: copy + drop> has copy, drop {
    parent_id: ID,
    data: Data,
}

/// Emitted when a platform link is removed. The phantom `Data` is the key.
public struct PlatformLinkRemovedEvent<phantom Data> has copy, drop {
    parent_id: ID,
}

// === Public Functions ===

/// Wraps a platform-specific payload into a link.
public fun new<Data: copy + drop + store>(data: Data): PlatformLink<Data> {
    PlatformLink { data }
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

// === View Functions ===

/// The wrapped platform-specific payload.
public fun data<Data: copy + drop + store>(self: &PlatformLink<Data>): Data {
    self.data
}

/// Whether a `PlatformLink<Data>` is stored under `uid`.
public fun exists_<Data: copy + drop + store>(uid: &UID): bool {
    df::exists(uid, PlatformLinkKey<Data>())
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

/// Maximum length in bytes of a platform identifier (handle, username, id or
/// subdomain). A shared storage backstop for every payload package.
public fun max_identifier_length(): u64 { 256 }

/// Maximum length in bytes of a stored URL, for payloads whose URL is the
/// identity. A shared storage backstop for every payload package.
public fun max_url_length(): u64 { 2000 }

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
