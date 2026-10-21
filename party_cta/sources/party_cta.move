// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Off-Miso call-to-action links for a party — the "what do you want people to
/// do" row (Tickets, Merch, Newsletter, external Listen, …).
///
/// Deliberately slim: a CTA is just a `{ label, url }`. On-Miso actions
/// (collect / listen-on-Miso / pin) are a different, interactive concern and
/// live in `party_featured`, which references object ids and can render live
/// state — so this package stays a plain, dependency-light external link hub.
///
/// The CTAs are an ordered list: **position is priority**. The whole list is
/// written at once (`set_ctas`) — the natural fit for a drag-to-reorder editor
/// that saves on submit — so there are no per-entry ids to track. Gated by the
/// `PartyAdminCap`; views are permissionless. A changed write emits the full new
/// list; a clear emits the party ID. Equal replacements and absent clears are
/// silent.
module party_cta::party_cta;

use miso_party::party::{Party, PartyAdminCap};
use std::string::String;
use sui::dynamic_field as df;
use sui::event::emit;

// === Errors ===

/// A CTA label must not be empty.
const EEmptyLabel: u64 = 0;
/// A CTA label exceeds the maximum length.
const ELabelTooLong: u64 = 1;
/// A CTA url must not be empty.
const EEmptyUrl: u64 = 2;
/// A CTA url exceeds the maximum length.
const EUrlTooLong: u64 = 3;
/// The list exceeds the maximum number of CTAs.
const ETooManyCtas: u64 = 4;

// === Constants ===

/// Maximum length of a CTA label in bytes.
const MAX_LABEL_LENGTH: u64 = 60;
/// Maximum length of a CTA url in bytes.
const MAX_URL_LENGTH: u64 = 2000;
/// Maximum number of CTAs on a party.
const MAX_CTAS: u64 = 20;

// === Keys ===

/// Dynamic-field key for a party's ordered CTA list.
public struct CtasKey() has copy, drop, store;

// === Types ===

/// A single call-to-action: a labeled external link.
public struct Cta has copy, drop, store {
    label: String,
    url: String,
}

// === Events ===

/// Emitted when a party's CTA list is set or changed; carries the full ordered list.
public struct CtasSetEvent has copy, drop {
    party_id: ID,
    ctas: vector<Cta>,
}

/// Emitted when a party's CTA list is cleared.
public struct CtasClearedEvent has copy, drop {
    party_id: ID,
}

// === Constructor / accessors ===

/// Builds a CTA. Aborts if the label or url is empty or too long. Callers build
/// the ordered `vector<Cta>` client-side and submit it with `set_ctas`.
public fun new_cta(label: String, url: String): Cta {
    assert!(!label.is_empty(), EEmptyLabel);
    assert!(label.length() <= MAX_LABEL_LENGTH, ELabelTooLong);
    assert!(!url.is_empty(), EEmptyUrl);
    assert!(url.length() <= MAX_URL_LENGTH, EUrlTooLong);
    Cta { label, url }
}

/// The CTA's display label.
public fun label(self: &Cta): String {
    self.label
}

/// The CTA's destination url.
public fun url(self: &Cta): String {
    self.url
}

// === Write API ===

/// Sets (or replaces) the party's ordered CTA list. Position is priority.
/// Length is checked before authorization. Emits the full list when it changes;
/// an empty first attachment emits, an equal replacement does not.
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

// === Views ===

/// Whether the party has a CTA list.
public fun has_ctas(self: &Party): bool {
    df::exists(self.uid(), CtasKey())
}

/// The party's ordered CTA list (empty if unset).
public fun ctas(self: &Party): vector<Cta> {
    if (!df::exists(self.uid(), CtasKey())) return vector[];
    *df::borrow<CtasKey, vector<Cta>>(self.uid(), CtasKey())
}

// === Test Functions ===

/// Test-only accessor for every `CtasSetEvent` field, in declaration order.
#[test_only]
public fun set_event_fields(event: &CtasSetEvent): (ID, vector<Cta>) {
    (event.party_id, event.ctas)
}

/// Test-only accessor for every `CtasClearedEvent` field.
#[test_only]
public fun cleared_event_fields(event: &CtasClearedEvent): ID {
    event.party_id
}
