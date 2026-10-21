// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

/// Free-form tags for a party: moods, scenes and descriptors (e.g. "ambient",
/// "deconstructed club").
///
/// The uncurated sibling to `party_genre`. Tags are stored as given (exact dedupe).
/// Duplicate, missing and over-max writes abort with `typed_set`'s error codes.
module party_tags::party_tags;

// === Imports ===

use std::string::String;
use sui::event::emit;
use miso_party::party::{Party, PartyAdminCap};
use typed_set::typed_set as set;

// === Errors ===

const EEmptyTag: u64 = 0;
const ETagTooLong: u64 = 1;

// === Constants ===

/// In bytes.
const MAX_TAG_LENGTH: u64 = 50;
const MAX_TAGS: u64 = 30;

// === Structs ===

/// Stored as a `VecSet<String>` through `typed_set`.
public struct TagsKey() has copy, drop, store;

// === Events ===

public struct TagAddedEvent has copy, drop {
    party_id: ID,
    tag: String,
}

public struct TagRemovedEvent has copy, drop {
    party_id: ID,
    tag: String,
}

public struct TagsClearedEvent has copy, drop {
    party_id: ID,
}

// === Public Functions ===

public fun add_tag(party: &mut Party, cap: &PartyAdminCap, tag: String) {
    assert!(!tag.is_empty(), EEmptyTag);
    assert!(tag.length() <= MAX_TAG_LENGTH, ETagTooLong);
    let party_id = object::id(party);
    set::add(party.uid_mut(cap), TagsKey(), tag, MAX_TAGS);
    emit(TagAddedEvent { party_id, tag });
}

/// The whole field is dropped when the last tag leaves, so `has_tags` tracks "carries
/// tags", not "has ever tagged".
public fun remove_tag(party: &mut Party, cap: &PartyAdminCap, tag: String) {
    let party_id = object::id(party);
    set::remove(party.uid_mut(cap), TagsKey(), tag);
    emit(TagRemovedEvent { party_id, tag });
}

/// No-op if none is set.
public fun clear_tags(party: &mut Party, cap: &PartyAdminCap) {
    let party_id = object::id(party);
    let uid = party.uid_mut(cap);
    if (set::exists(uid, TagsKey())) {
        set::clear<TagsKey, String>(uid, TagsKey());
        emit(TagsClearedEvent { party_id });
    }
}

// === View Functions ===

public fun has_tags(party: &Party): bool {
    set::exists(party.uid(), TagsKey())
}

public fun has_tag(party: &Party, tag: String): bool {
    set::contains(party.uid(), TagsKey(), &tag)
}

public fun tags(party: &Party): vector<String> {
    set::keys(party.uid(), TagsKey())
}

// === Test Functions ===

#[test_only]
public fun added_event_fields(event: &TagAddedEvent): (ID, String) {
    (event.party_id, event.tag)
}

#[test_only]
public fun removed_event_fields(event: &TagRemovedEvent): (ID, String) {
    (event.party_id, event.tag)
}

#[test_only]
public fun cleared_event_fields(event: &TagsClearedEvent): ID {
    event.party_id
}
