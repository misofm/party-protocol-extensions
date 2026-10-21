// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Off-Miso call-to-action links for a party (Tickets, Merch, Newsletter, external Listen).
///
/// On-Miso actions live in `party_featured`. The CTAs are one ordered list (position is
/// priority) written whole with `set_ctas`, so there are no per-entry ids. Equal
/// replacements and absent clears are silent.
module party_cta::party_cta;

// === Imports ===

use std::string::String;
use sui::dynamic_field as df;
use sui::event::emit;
use miso_party::party::{Party, PartyAdminCap};

// === Errors ===

const EEmptyLabel: u64 = 0;
const ELabelTooLong: u64 = 1;
const EEmptyUrl: u64 = 2;
const EUrlTooLong: u64 = 3;
const ETooManyCtas: u64 = 4;

// === Constants ===

/// In bytes.
const MAX_LABEL_LENGTH: u64 = 60;
/// In bytes.
const MAX_URL_LENGTH: u64 = 2000;
const MAX_CTAS: u64 = 20;

// === Structs ===

public struct Cta has copy, drop, store {
    label: String,
    url: String,
}

public struct CtasKey() has copy, drop, store;

// === Events ===

public struct CtasSetEvent has copy, drop {
    party_id: ID,
    ctas: vector<Cta>,
}

public struct CtasClearedEvent has copy, drop {
    party_id: ID,
}

// === Public Functions ===

public fun new_cta(label: String, url: String): Cta {
    assert!(!label.is_empty(), EEmptyLabel);
    assert!(label.length() <= MAX_LABEL_LENGTH, ELabelTooLong);
    assert!(!url.is_empty(), EEmptyUrl);
    assert!(url.length() <= MAX_URL_LENGTH, EUrlTooLong);
    Cta { label, url }
}

/// Position is priority. Length is checked before authorization. An empty first
/// attachment emits; an equal replacement does not.
public fun set_ctas(self: &mut Party, cap: &PartyAdminCap, ctas: vector<Cta>) {
    assert!(ctas.length() <= MAX_CTAS, ETooManyCtas);
    let party_id = object::id(self);
    let uid = self.uid_mut(cap);
    if (df::exists(uid, CtasKey())) {
        let previous: &mut vector<Cta> = df::borrow_mut(uid, CtasKey());
        if (*previous == ctas) return;
        *previous = ctas;
    } else {
        df::add(uid, CtasKey(), ctas);
    };
    emit(CtasSetEvent { party_id, ctas });
}

/// Removes the party's CTA list. Authorization happens before checking
/// existence; an absent list is a silent no-op.
public fun clear_ctas(self: &mut Party, cap: &PartyAdminCap) {
    let party_id = object::id(self);
    let uid = self.uid_mut(cap);
    if (df::exists(uid, CtasKey())) {
        let _: vector<Cta> = df::remove(uid, CtasKey());
        emit(CtasClearedEvent { party_id });
    }
}

// === View Functions ===

public fun has_ctas(self: &Party): bool {
    df::exists(self.uid(), CtasKey())
}

public fun ctas(self: &Party): vector<Cta> {
    if (!df::exists(self.uid(), CtasKey())) return vector[];
    *df::borrow<CtasKey, vector<Cta>>(self.uid(), CtasKey())
}

public fun label(self: &Cta): String {
    self.label
}

public fun url(self: &Cta): String {
    self.url
}

// === Test Functions ===

#[test_only]
public fun set_event_fields(event: &CtasSetEvent): (ID, vector<Cta>) {
    (event.party_id, event.ctas)
}

#[test_only]
public fun cleared_event_fields(event: &CtasClearedEvent): ID {
    event.party_id
}
