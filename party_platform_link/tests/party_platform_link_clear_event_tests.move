// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module party_platform_link::party_platform_link_clear_event_tests;

// === Imports ===

use std::unit_test::{assert_eq, destroy};
use sui::event;
use miso_party::party;
use party_social::party_social::{Self as social, XData};
use platform_link::platform_link as primitive;
use party_platform_link::party_platform_link as links;

fun new_party(ctx: &mut TxContext): (party::Party, party::PartyAdminCap) {
    party::new(party::new_individual_kind(), b"Test Artist".to_string(), ctx)
}

#[test]
fun present_clear_event_and_absent_repeat_are_precise() {
    let ctx = &mut tx_context::dummy();
    let (mut p, cap) = new_party(ctx);
    let parent_id = object::id(&p);

    let before = event::num_events();
    links::clear_link<XData>(&mut p, &cap);
    assert_eq!(event::num_events(), before);
    assert_eq!(event::events_by_type<primitive::PlatformLinkRemovedEvent<XData>>().length(), 0);

    let link = social::x(b"second".to_string());
    links::set_link(&mut p, &cap, link);
    let set_count = event::events_by_type<primitive::PlatformLinkSetEvent<XData>>().length();
    assert_eq!(set_count, 1);

    let before = event::num_events();
    links::clear_link<XData>(&mut p, &cap);
    assert_eq!(event::num_events(), before + 1);
    assert!(!links::has_link<XData>(&p));
    let removed = event::events_by_type<primitive::PlatformLinkRemovedEvent<XData>>();
    assert_eq!(removed.length(), 1);
    assert_eq!(primitive::removed_event_fields(&removed[0]), parent_id);

    let before = event::num_events();
    links::clear_link<XData>(&mut p, &cap);
    assert_eq!(event::num_events(), before);
    assert!(links::link<XData>(&p).is_none());
    assert_eq!(event::events_by_type<primitive::PlatformLinkSetEvent<XData>>().length(), set_count);
    assert_eq!(event::events_by_type<primitive::PlatformLinkRemovedEvent<XData>>().length(), 1);

    destroy(p);
    destroy(cap);
}
