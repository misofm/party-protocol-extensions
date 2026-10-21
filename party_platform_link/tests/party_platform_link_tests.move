// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

#[test_only]
module party_platform_link::party_platform_link_tests;

// === Imports ===

use std::unit_test::{assert_eq, destroy};
use sui::event;
use sui::test_scenario::{Self as ts};
use miso_party::party;
use party_social::party_social::{Self as social, XData, InstagramData};
use platform_link::platform_link::{Self as primitive, PlatformLinkRemovedEvent};
use party_platform_link::party_platform_link as links;

const OWNER: address = @0xA;

fun new_party(ctx: &mut TxContext): (party::Party, party::PartyAdminCap) {
    party::new(party::new_individual_kind(), b"Test Artist".to_string(), ctx)
}

#[test]
fun x_and_instagram_events_keep_distinct_parties_and_types() {
    let ctx = &mut tx_context::dummy();
    let (mut x_party, x_cap) = new_party(ctx);
    let (mut instagram_party, instagram_cap) = new_party(ctx);
    let x_parent_id = object::id(&x_party);
    let instagram_parent_id = object::id(&instagram_party);
    assert!(x_parent_id != instagram_parent_id);

    let x_link = social::x(b"miso".to_string());
    let instagram_link = social::instagram(b"miso.fm".to_string());

    links::set_link(&mut x_party, &x_cap, x_link);
    links::set_link(&mut instagram_party, &instagram_cap, instagram_link);

    let x_events = event::events_by_type<primitive::PlatformLinkSetEvent<XData>>();
    let instagram_events = event::events_by_type<primitive::PlatformLinkSetEvent<InstagramData>>();
    assert_eq!(x_events.length(), 1);
    assert_eq!(instagram_events.length(), 1);
    let (event_parent_id, event_data) = primitive::set_event_fields(&x_events[0]);
    assert_eq!(event_parent_id, x_parent_id);
    assert_eq!(event_data.handle(), b"miso".to_string());
    let (event_parent_id, event_data) = primitive::set_event_fields(&instagram_events[0]);
    assert_eq!(event_parent_id, instagram_parent_id);
    assert_eq!(event_data.handle(), b"miso.fm".to_string());

    links::clear_link<XData>(&mut x_party, &x_cap);
    links::clear_link<InstagramData>(&mut instagram_party, &instagram_cap);
    let x_removed = event::events_by_type<PlatformLinkRemovedEvent<XData>>();
    let instagram_removed = event::events_by_type<PlatformLinkRemovedEvent<InstagramData>>();
    assert_eq!(x_removed.length(), 1);
    assert_eq!(instagram_removed.length(), 1);
    assert_eq!(primitive::removed_event_fields(&x_removed[0]), x_parent_id);
    assert_eq!(primitive::removed_event_fields(&instagram_removed[0]), instagram_parent_id);

    destroy(x_party);
    destroy(x_cap);
    destroy(instagram_party);
    destroy(instagram_cap);
}

#[test]
fun shared_party_cap_holder_and_reader() {
    let mut scenario = ts::begin(OWNER);
    let (p, cap) = new_party(scenario.ctx());
    let parent_id = object::id(&p);
    party::share(p, &cap);
    transfer::public_transfer(cap, OWNER);

    scenario.next_tx(OWNER);
    let mut p = scenario.take_shared<party::Party>();
    let cap = scenario.take_from_sender<party::PartyAdminCap>();
    links::set_link(&mut p, &cap, social::x(b"miso".to_string()));
    let set_events = event::events_by_type<primitive::PlatformLinkSetEvent<XData>>();
    assert_eq!(set_events.length(), 1);
    let (event_parent_id, event_data) = primitive::set_event_fields(&set_events[0]);
    assert_eq!(event_parent_id, parent_id);
    assert_eq!(event_data.handle(), b"miso".to_string());
    ts::return_shared(p);
    scenario.return_to_sender(cap);

    scenario.next_tx(@0xB);
    let p = scenario.take_shared<party::Party>();
    let before = event::num_events();
    assert!(links::has_link<XData>(&p));
    assert_eq!(links::link<XData>(&p).destroy_some().data().handle(), b"miso".to_string());
    assert_eq!(event::num_events(), before);
    assert_eq!(event::events_by_type<primitive::PlatformLinkSetEvent<XData>>().length(), 0);
    assert_eq!(event::events_by_type<primitive::PlatformLinkRemovedEvent<XData>>().length(), 0);
    ts::return_shared(p);
    scenario.end();
}
