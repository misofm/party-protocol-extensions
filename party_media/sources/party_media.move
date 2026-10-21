// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Profile imagery for a party, stored as a single Walrus quilt.
///
/// All of a party's images (avatar, header/cover, …) live together in one Walrus
/// quilt — batching them under a single storage reservation is markedly cheaper
/// than one blob each, which matters when the platform sponsors storage. Only the
/// quilt's blob id is held on-chain, as a `Media` dynamic field on the party's
/// UID, gated by the `PartyAdminCap`; views are permissionless.
///
/// The chain is deliberately role-agnostic: which patch is the avatar vs the
/// header is a client convention (quilt patch *identifiers*, e.g. "avatar" /
/// "header"), derived off-chain — never stored here. Updating any image means
/// re-storing the quilt and calling `set_media` with the new id.
/// A changed set emits the new quilt id; a clear emits the party ID. Equal
/// replacements and absent clears are silent.
module party_media::party_media;

use miso_party::party::{Party, PartyAdminCap};
use sui::dynamic_field as df;
use sui::event::emit;

// === Keys ===

/// Dynamic-field key for a party's media.
public struct MediaKey() has copy, drop, store;

// === Errors ===

/// The quilt id was zero. Zero is never a real Walrus blob id — almost
/// certainly a caller bug, and indistinguishable from "unset" downstream.
const EZeroQuilt: u64 = 0;

// === Types ===

/// A party's imagery. Held as a dynamic-field value.
public struct Media has store, drop {
    /// Walrus quilt blob id holding all of the party's images. Individual images
    /// are quilt patches addressed by identifier ("avatar", "header", …); those
    /// roles are a client convention, derived off-chain, not stored here.
    quilt: u256,
}

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

// === Write API ===

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

// === Views ===

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
