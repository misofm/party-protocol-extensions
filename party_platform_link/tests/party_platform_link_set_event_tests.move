// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

#[test_only]
module party_platform_link::party_platform_link_set_event_tests;

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
fun insert_different_and_equal_replace_events() {
    let ctx = &mut tx_context::dummy();
    let (mut p, cap) = new_party(ctx);
    let parent_id = object::id(&p);
    let first = social::x(b"first".to_string());
    let second = social::x(b"second".to_string());

    let before = event::num_events();
    links::clear_link<XData>(&mut p, &cap);
    assert_eq!(event::num_events(), before);
    assert!(!links::has_link<XData>(&p));
    assert!(links::link<XData>(&p).is_none());
    assert_eq!(event::num_events(), before);
    assert_eq!(event::events_by_type<primitive::PlatformLinkSetEvent<XData>>().length(), 0);
    assert_eq!(event::events_by_type<primitive::PlatformLinkRemovedEvent<XData>>().length(), 0);

    links::set_link(&mut p, &cap, first);
    assert_eq!(event::num_events(), before + 1);
    let sets = event::events_by_type<primitive::PlatformLinkSetEvent<XData>>();
    assert_eq!(sets.length(), 1);
    let (event_parent_id, event_data) = primitive::set_event_fields(&sets[0]);
    assert_eq!(event_parent_id, parent_id);
    assert_eq!(event_data.handle(), b"first".to_string());

    links::set_link(&mut p, &cap, second);
    assert_eq!(event::num_events(), before + 2);
    let sets = event::events_by_type<primitive::PlatformLinkSetEvent<XData>>();
    assert_eq!(sets.length(), 2);
    let (event_parent_id, event_data) = primitive::set_event_fields(&sets[1]);
    assert_eq!(event_parent_id, parent_id);
    assert_eq!(event_data.handle(), b"second".to_string());

    links::set_link(&mut p, &cap, social::x(b"second".to_string()));
    assert_eq!(event::num_events(), before + 2);
    let sets = event::events_by_type<primitive::PlatformLinkSetEvent<XData>>();
    assert_eq!(sets.length(), 2);
    assert_eq!(links::link<XData>(&p).destroy_some().data().handle(), b"second".to_string());

    links::clear_link<XData>(&mut p, &cap);
    destroy(p);
    destroy(cap);
}
