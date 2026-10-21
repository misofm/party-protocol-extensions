// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

/// Profile imagery for a party, stored as a single Walrus quilt.
///
/// All of a party's images (avatar, header, ...) live in one quilt, cheaper than one blob
/// each; only its blob id is held on-chain. Which patch is the avatar or header is a client
/// convention (quilt patch identifiers), never stored here. Equal replacements and absent
/// clears are silent.
module party_media::party_media;

// === Imports ===

use sui::dynamic_field as df;
use sui::event::emit;
use miso_party::party::{Party, PartyAdminCap};

// === Errors ===

/// Zero is never a real Walrus blob id.
const EZeroQuilt: u64 = 0;

// === Structs ===

public struct Media has store, drop {
    /// Walrus quilt blob id.
    quilt: u256,
}

public struct MediaKey() has copy, drop, store;

// === Events ===

public struct MediaSetEvent has copy, drop {
    party_id: ID,
    quilt: u256,
}

public struct MediaClearedEvent has copy, drop {
    party_id: ID,
}

// === Public Functions ===

/// The zero check runs before authorization.
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

public fun has_media(self: &Party): bool {
    df::exists(self.uid(), MediaKey())
}

public fun quilt(self: &Party): Option<u256> {
    if (!df::exists(self.uid(), MediaKey())) return option::none();
    option::some(df::borrow<MediaKey, Media>(self.uid(), MediaKey()).quilt)
}

// === Test Functions ===

#[test_only]
public fun set_event_fields(event: &MediaSetEvent): (ID, u256) {
    (event.party_id, event.quilt)
}

#[test_only]
public fun cleared_event_fields(event: &MediaClearedEvent): ID {
    event.party_id
}
