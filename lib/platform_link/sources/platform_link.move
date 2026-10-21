// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// `PlatformLink<Data>`: a typed link to an entity on one external platform.
///
/// `Data` is the platform's native identifier (a handle, an artist id, a subdomain), defined
/// in its own small package, so adding a platform is a new type, never a change here. URLs
/// are not stored; clients rebuild them from `Data`. One link per `Data` type per `UID`.
module platform_link::platform_link;

// === Imports ===

use sui::dynamic_field as df;
use sui::event::emit;

// === Errors ===

const ENoLink: u64 = 0;

// === Structs ===

public struct PlatformLink<Data: copy + drop + store> has copy, drop, store {
    data: Data,
}

public struct PlatformLinkKey<phantom Data>() has copy, drop, store;

// === Events ===

public struct PlatformLinkSetEvent<Data: copy + drop> has copy, drop {
    parent_id: ID,
    data: Data,
}

public struct PlatformLinkRemovedEvent<phantom Data> has copy, drop {
    parent_id: ID,
}

// === Public Functions ===

public fun new<Data: copy + drop + store>(data: Data): PlatformLink<Data> {
    PlatformLink { data }
}

/// Emits only when the value changes; an equal replacement is a no-op.
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

public fun remove<Data: copy + drop + store>(uid: &mut UID): PlatformLink<Data> {
    assert!(df::exists(uid, PlatformLinkKey<Data>()), ENoLink);
    let link: PlatformLink<Data> = df::remove(uid, PlatformLinkKey<Data>());
    emit(PlatformLinkRemovedEvent<Data> { parent_id: uid.to_inner() });
    link
}

/// No-op if absent.
public fun clear<Data: copy + drop + store>(uid: &mut UID) {
    if (df::exists(uid, PlatformLinkKey<Data>())) {
        let _: PlatformLink<Data> = df::remove(uid, PlatformLinkKey<Data>());
        emit(PlatformLinkRemovedEvent<Data> { parent_id: uid.to_inner() });
    }
}

// === View Functions ===

public fun data<Data: copy + drop + store>(self: &PlatformLink<Data>): Data {
    self.data
}

public fun exists_<Data: copy + drop + store>(uid: &UID): bool {
    df::exists(uid, PlatformLinkKey<Data>())
}

public fun get<Data: copy + drop + store>(uid: &UID): Option<PlatformLink<Data>> {
    if (df::exists(uid, PlatformLinkKey<Data>())) {
        option::some(*df::borrow(uid, PlatformLinkKey<Data>()))
    } else {
        option::none()
    }
}

public fun borrow<Data: copy + drop + store>(uid: &UID): &PlatformLink<Data> {
    assert!(df::exists(uid, PlatformLinkKey<Data>()), ENoLink);
    df::borrow(uid, PlatformLinkKey<Data>())
}

/// Max bytes of a platform identifier; a shared storage backstop for payload packages.
public fun max_identifier_length(): u64 { 256 }

/// Max bytes of a URL, for payloads whose URL is the identity.
public fun max_url_length(): u64 { 2000 }

// === Test Functions ===

#[test_only]
public fun set_event_fields<Data: copy + drop>(event: &PlatformLinkSetEvent<Data>): (ID, Data) {
    (event.parent_id, event.data)
}

#[test_only]
public fun removed_event_fields<Data>(event: &PlatformLinkRemovedEvent<Data>): ID {
    event.parent_id
}
