// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

#[test_only]
module party_platform_link::party_platform_link_auth_tests;

// === Imports ===

use miso_party::party;
use party_social::party_social as social;
use party_platform_link::party_platform_link as links;

fun new_party(ctx: &mut TxContext): (party::Party, party::PartyAdminCap) {
    party::new(party::new_individual_kind(), b"Test Artist".to_string(), ctx)
}

#[test, expected_failure(abort_code = party::EUnauthorized)]
fun set_link_with_wrong_cap_aborts_when_absent() {
    let ctx = &mut tx_context::dummy();
    let (mut p, _cap) = new_party(ctx);
    let (_other, other_cap) = new_party(ctx);
    links::set_link(&mut p, &other_cap, social::x(b"miso".to_string()));
    abort
}

#[test, expected_failure(abort_code = party::EUnauthorized)]
fun set_link_with_wrong_cap_aborts_when_existing() {
    let ctx = &mut tx_context::dummy();
    let (mut p, cap) = new_party(ctx);
    let (_other, other_cap) = new_party(ctx);
    links::set_link(&mut p, &cap, social::x(b"old".to_string()));
    links::set_link(&mut p, &other_cap, social::x(b"new".to_string()));
    abort
}

#[test, expected_failure(abort_code = party::EUnauthorized)]
fun set_link_equal_with_wrong_cap_aborts() {
    let ctx = &mut tx_context::dummy();
    let (mut p, cap) = new_party(ctx);
    let (_other, other_cap) = new_party(ctx);
    links::set_link(&mut p, &cap, social::x(b"same".to_string()));

    links::set_link(&mut p, &other_cap, social::x(b"same".to_string()));
    abort
}

#[test, expected_failure(abort_code = party::EUnauthorized)]
fun clear_link_with_wrong_cap_aborts_when_absent() {
    let ctx = &mut tx_context::dummy();
    let (mut p, _cap) = new_party(ctx);
    let (_other, other_cap) = new_party(ctx);
    links::clear_link<social::XData>(&mut p, &other_cap);
    abort
}

#[test, expected_failure(abort_code = party::EUnauthorized)]
fun clear_link_with_wrong_cap_aborts_when_existing() {
    let ctx = &mut tx_context::dummy();
    let (mut p, cap) = new_party(ctx);
    let (_other, other_cap) = new_party(ctx);
    links::set_link(&mut p, &cap, social::x(b"miso".to_string()));
    links::clear_link<social::XData>(&mut p, &other_cap);
    abort
}
