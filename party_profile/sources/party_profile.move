// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A party's editable profile card: the free-form identity fields a profile
/// page renders.
///
/// Stored as one `Profile` dynamic field on the party's UID, gated by the
/// `PartyAdminCap`; views are permissionless. Roles, tags, genres, media and
/// links each live in their own extension. `country` and `languages` use the
/// validated `country_code` / `language_code` types. The party's name lives on
/// the core `Party`, and the join date comes from its creation event. A changed
/// set emits every profile field, a clear emits the party ID; equal
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

/// Short bio must not be empty.
const EEmptyBioShort: u64 = 0;
/// Short bio exceeds the maximum length.
const EBioShortTooLong: u64 = 1;
/// Long bio must not be empty when provided.
const EEmptyBioLong: u64 = 2;
/// Long bio exceeds the maximum length.
const EBioLongTooLong: u64 = 3;
/// Too many language tags.
const ETooManyLanguages: u64 = 4;
/// No profile is set on this party.
const ENoProfile: u64 = 5;
/// A language tag appears more than once.
const EDuplicateLanguage: u64 = 6;

// === Constants ===

/// Maximum length of the short bio in bytes.
const MAX_BIO_SHORT_LENGTH: u64 = 300;
/// Maximum length of the long bio in bytes (8 KB, matching
/// `release_description`); a storage backstop, not an editorial limit.
const MAX_BIO_LONG_LENGTH: u64 = 8192;
/// Maximum number of language tags.
const MAX_LANGUAGES: u64 = 10;

// === Structs ===

/// A party's profile card. Held as a dynamic-field value, not a standalone
/// object.
public struct Profile has store, drop {
    bio_short: String,
    bio_long: Option<String>,
    country: Option<CountryCode>,
    languages: vector<LanguageCode>,
}

/// Dynamic-field key for a party's profile.
public struct ProfileKey() has copy, drop, store;

// === Events ===

/// Emitted when a party's profile is set or changed; carries the full profile.
public struct PartyProfileSetEvent has copy, drop {
    party_id: ID,
    bio_short: String,
    bio_long: Option<String>,
    country: Option<CountryCode>,
    languages: vector<LanguageCode>,
}

/// Emitted when a party's profile is cleared.
public struct PartyProfileClearedEvent has copy, drop {
    party_id: ID,
}

// === Public Functions ===

/// Sets (creates or replaces) the party's whole profile. Validation happens
/// before authorization. Emits the full profile when it changes; an initial
/// profile always emits, an equal replacement does not.
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

/// Whether the party has a profile.
public fun has_profile(self: &Party): bool {
    df::exists(self.uid(), ProfileKey())
}

/// Borrows the party's profile. Aborts if none is set.
public fun profile(self: &Party): &Profile {
    assert!(df::exists(self.uid(), ProfileKey()), ENoProfile);
    df::borrow(self.uid(), ProfileKey())
}

/// The profile's short bio.
public fun bio_short(self: &Profile): String {
    self.bio_short
}

/// The profile's long bio, if set.
public fun bio_long(self: &Profile): Option<String> {
    self.bio_long
}

/// The profile's country, if set.
public fun country(self: &Profile): Option<CountryCode> {
    self.country
}

/// The profile's language tags.
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

/// Test-only accessor for every `PartyProfileSetEvent` field, in declaration order.
#[test_only]
public fun set_event_fields(
    event: &PartyProfileSetEvent,
): (ID, String, Option<String>, Option<CountryCode>, vector<LanguageCode>) {
    (event.party_id, event.bio_short, event.bio_long, event.country, event.languages)
}

/// Test-only accessor for every `PartyProfileClearedEvent` field.
#[test_only]
public fun cleared_event_fields(event: &PartyProfileClearedEvent): ID {
    event.party_id
}
