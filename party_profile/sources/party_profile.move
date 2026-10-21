// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

/// A party's editable profile card: the free-form identity fields a profile page renders.
///
/// Roles, tags, genres, media and links each live in their own extension. The party's name
/// lives on the core `Party`, and the join date comes from its creation event. Equal
/// replacements and absent clears are silent.
module party_profile::party_profile;

// === Imports ===

use std::string::String;
use sui::dynamic_field as df;
use sui::event::emit;
use sui::vec_set;
use country_code::country_code::CountryCode;
use language_code::language_code::LanguageCode;
use miso_party::party::{Party, PartyAdminCap};

// === Errors ===

const EEmptyBioShort: u64 = 0;
const EBioShortTooLong: u64 = 1;
const EEmptyBioLong: u64 = 2;
const EBioLongTooLong: u64 = 3;
const ETooManyLanguages: u64 = 4;
const ENoProfile: u64 = 5;
const EDuplicateLanguage: u64 = 6;

// === Constants ===

/// In bytes.
const MAX_BIO_SHORT_LENGTH: u64 = 300;
/// In bytes (8 KB, matching `release_description`); a storage backstop, not an editorial
/// limit.
const MAX_BIO_LONG_LENGTH: u64 = 8192;
const MAX_LANGUAGES: u64 = 10;

// === Structs ===

public struct Profile has store, drop {
    bio_short: String,
    bio_long: Option<String>,
    country: Option<CountryCode>,
    languages: vector<LanguageCode>,
}

public struct ProfileKey() has copy, drop, store;

// === Events ===

public struct PartyProfileSetEvent has copy, drop {
    party_id: ID,
    bio_short: String,
    bio_long: Option<String>,
    country: Option<CountryCode>,
    languages: vector<LanguageCode>,
}

public struct PartyProfileClearedEvent has copy, drop {
    party_id: ID,
}

// === Public Functions ===

/// Validation happens before authorization. An initial profile always emits; an equal
/// replacement does not.
public fun set_profile(
    self: &mut Party,
    cap: &PartyAdminCap,
    bio_short: String,
    bio_long: Option<String>,
    country: Option<CountryCode>,
    languages: vector<LanguageCode>,
) {
    validate_bio_short(&bio_short);
    bio_long.do_ref!(|bio| {
        assert!(!bio.is_empty(), EEmptyBioLong);
        assert!(bio.length() <= MAX_BIO_LONG_LENGTH, EBioLongTooLong);
    });
    validate_languages(&languages);

    let party_id = object::id(self);
    let event = PartyProfileSetEvent { party_id, bio_short, bio_long, country, languages };
    let profile = Profile { bio_short, bio_long, country, languages };
    let uid = self.uid_mut(cap);
    if (df::exists(uid, ProfileKey())) {
        let previous: &mut Profile = df::borrow_mut(uid, ProfileKey());
        if (previous == &profile) return;
        *previous = profile;
    } else {
        df::add(uid, ProfileKey(), profile);
    };
    emit(event);
}

/// Removes the party's profile. Authorization happens before checking
/// existence; an absent field is a silent no-op.
public fun clear_profile(self: &mut Party, cap: &PartyAdminCap) {
    let party_id = object::id(self);
    let uid = self.uid_mut(cap);
    if (df::exists(uid, ProfileKey())) {
        let _: Profile = df::remove(uid, ProfileKey());
        emit(PartyProfileClearedEvent { party_id });
    }
}

// === View Functions ===

public fun has_profile(self: &Party): bool {
    df::exists(self.uid(), ProfileKey())
}

public fun profile(self: &Party): &Profile {
    assert!(df::exists(self.uid(), ProfileKey()), ENoProfile);
    df::borrow(self.uid(), ProfileKey())
}

public fun bio_short(self: &Profile): String {
    self.bio_short
}

public fun bio_long(self: &Profile): Option<String> {
    self.bio_long
}

public fun country(self: &Profile): Option<CountryCode> {
    self.country
}

public fun languages(self: &Profile): vector<LanguageCode> {
    self.languages
}

// === Private Functions ===

fun validate_bio_short(bio_short: &String) {
    assert!(!bio_short.is_empty(), EEmptyBioShort);
    assert!(bio_short.length() <= MAX_BIO_SHORT_LENGTH, EBioShortTooLong);
}

// Codes are valid by construction; only count and duplicates are checked.
fun validate_languages(languages: &vector<LanguageCode>) {
    assert!(languages.length() <= MAX_LANGUAGES, ETooManyLanguages);
    let mut seen = vec_set::empty<LanguageCode>();
    languages.do_ref!(|l| {
        assert!(!seen.contains(l), EDuplicateLanguage);
        seen.insert(*l);
    });
}

// === Test Functions ===

#[test_only]
public fun set_event_fields(
    event: &PartyProfileSetEvent,
): (ID, String, Option<String>, Option<CountryCode>, vector<LanguageCode>) {
    (event.party_id, event.bio_short, event.bio_long, event.country, event.languages)
}

#[test_only]
public fun cleared_event_fields(event: &PartyProfileClearedEvent): ID {
    event.party_id
}
