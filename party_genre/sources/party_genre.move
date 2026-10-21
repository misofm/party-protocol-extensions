// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Musical-genre tags for a party, drawn from the Miso genre vocabulary.
///
/// Stores a set of `genre::Genre` ids, the same canonical ids releases use.
/// Adding takes a `&Genre`, proving the id is a real vocabulary entry; removal
/// is by id. Genres are a display tag list with no ranking. Set mechanics
/// (storage, duplicate and capacity checks, field reclamation) live in
/// `typed_set`, whose error codes surface on duplicate, missing and over-max
/// writes. Writes are gated by the `PartyAdminCap`; views are permissionless.
module party_genre::party_genre;

// === Imports ===

use std::string::String;
use sui::event::emit;
use genre::genre::Genre;
use miso_party::party::{Party, PartyAdminCap};
use typed_set::typed_set as set;

// === Constants ===

/// Maximum number of genres a party may carry.
const MAX_GENRES: u64 = 20;

// === Structs ===

/// Dynamic-field key for a party's genre set, stored as a `VecSet<ID>` and
/// managed through `typed_set`.
public struct GenresKey() has copy, drop, store;

// === Events ===

/// Emitted when a genre is added to a party; carries the genre's name.
public struct GenreAddedEvent has copy, drop {
    party_id: ID,
    genre_id: ID,
    genre_name: String,
}

/// Emitted when a genre is removed from a party.
public struct GenreRemovedEvent has copy, drop {
    party_id: ID,
    genre_id: ID,
}

/// Emitted when a party's entire genre set is removed.
public struct GenresClearedEvent has copy, drop {
    party_id: ID,
}

// === Public Functions ===

/// Adds a genre to the party. Takes `&Genre` so only a real vocabulary entry
/// can be tagged. Aborts in `typed_set` if already present or the max is
/// reached.
public fun add_genre(self: &mut Party, cap: &PartyAdminCap, genre: &Genre) {
    let party_id = object::id(self);
    let genre_id = object::id(genre);
    set::add(self.uid_mut(cap), GenresKey(), genre_id, MAX_GENRES);
    emit(GenreAddedEvent { party_id, genre_id, genre_name: *genre.name() });
}

/// Removes a genre from the party. Aborts in `typed_set` if not present. The
/// whole field is dropped when the last genre leaves.
public fun remove_genre(self: &mut Party, cap: &PartyAdminCap, genre_id: ID) {
    let party_id = object::id(self);
    set::remove(self.uid_mut(cap), GenresKey(), genre_id);
    emit(GenreRemovedEvent { party_id, genre_id });
}

/// Removes the party's entire genre set. No-op if none is set.
public fun clear_genres(self: &mut Party, cap: &PartyAdminCap) {
    let party_id = object::id(self);
    let uid = self.uid_mut(cap);
    if (set::exists(uid, GenresKey())) {
        set::clear<GenresKey, ID>(uid, GenresKey());
        emit(GenresClearedEvent { party_id });
    }
}

// === View Functions ===

/// Whether the party carries any genres.
public fun has_genres(self: &Party): bool {
    set::exists(self.uid(), GenresKey())
}

/// Whether the party carries the given genre.
public fun has_genre(self: &Party, genre_id: ID): bool {
    set::contains(self.uid(), GenresKey(), &genre_id)
}

/// The party's genre ids.
public fun genres(self: &Party): vector<ID> {
    set::keys(self.uid(), GenresKey())
}

// === Test Functions ===

/// Test-only accessor for every `GenreAddedEvent` field, in declaration order.
#[test_only]
public fun added_event_fields(event: &GenreAddedEvent): (ID, ID, String) {
    (event.party_id, event.genre_id, event.genre_name)
}

/// Test-only accessor for every `GenreRemovedEvent` field, in declaration order.
#[test_only]
public fun removed_event_fields(event: &GenreRemovedEvent): (ID, ID) {
    (event.party_id, event.genre_id)
}

/// Test-only accessor for every `GenresClearedEvent` field.
#[test_only]
public fun cleared_event_fields(event: &GenresClearedEvent): ID {
    event.party_id
}
