// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Profile imagery for a party, stored as a single Walrus quilt.
///
/// All of a party's images (avatar, header, ...) live in one quilt, which is
/// cheaper than one blob each. Only the quilt's blob id is held on-chain, as a
/// `Media` dynamic field gated by the `PartyAdminCap`; views are
/// permissionless. Which patch is the avatar or header is a client convention
/// (quilt patch identifiers), never stored here. A changed set emits the new
/// quilt id, a clear emits the party ID; equal replacements and absent clears
/// are silent.
module party_media::party_media;

// === Imports ===

use sui::dynamic_field as df;
use sui::event::emit;
use miso_party::party::{Party, PartyAdminCap};

// === Errors ===

/// The quilt id was zero, which is never a real Walrus blob id.
const EZeroQuilt: u64 = 0;

// === Structs ===

/// A party's imagery. Held as a dynamic-field value.
public struct Media has store, drop {
    /// Walrus quilt blob id holding all of the party's images.
    quilt: u256,
}

/// Dynamic-field key for a party's media.
public struct MediaKey() has copy, drop, store;

// === Events ===

/// Emitted when a party's media quilt is set or changed; carries the new id.
public struct MediaSetEvent has copy, drop {
    party_id: ID,
    quilt: u256,
}

/// Emitted when a party's media is removed.
public struct MediaClearedEvent has copy, drop {
    party_id: ID,
}

// === Public Functions ===

/// Sets (or replaces) the party's media quilt. Aborts on a zero id before
/// authorization. Emits the new id when it changes; an equal id is silent.
public fun set_media(self: &mut Party, cap: &PartyAdminCap, quilt: u256) {
    assert!(quilt != 0, EZeroQuilt);
    let party_id = object::id(self);
    let uid = self.uid_mut(cap);
    if (df::exists(uid, MediaKey())) {
        let media: &mut Media = df::borrow_mut(uid, MediaKey());
        if (media.quilt == quilt) return;
        media.quilt = quilt;
    } else {
        df::add(uid, MediaKey(), Media { quilt });
    };
    emit(MediaSetEvent { party_id, quilt });
}

/// Removes the party's media. Authorization happens before checking
/// existence; an absent field is a silent no-op.
public fun clear_media(self: &mut Party, cap: &PartyAdminCap) {
    let party_id = object::id(self);
    let uid = self.uid_mut(cap);
    if (df::exists(uid, MediaKey())) {
        let Media { quilt: _ } = df::remove(uid, MediaKey());
        emit(MediaClearedEvent { party_id });
    }
}

// === View Functions ===

/// Whether the party has media set.
public fun has_media(self: &Party): bool {
    df::exists(self.uid(), MediaKey())
}

/// The party's media quilt id, if set.
public fun quilt(self: &Party): Option<u256> {
    if (!df::exists(self.uid(), MediaKey())) return option::none();
    option::some(df::borrow<MediaKey, Media>(self.uid(), MediaKey()).quilt)
}

// === Test Functions ===

/// Test-only accessor for every `MediaSetEvent` field, in declaration order.
#[test_only]
public fun set_event_fields(event: &MediaSetEvent): (ID, u256) {
    (event.party_id, event.quilt)
}

/// Test-only accessor for every `MediaClearedEvent` field.
#[test_only]
public fun cleared_event_fields(event: &MediaClearedEvent): ID {
    event.party_id
}
