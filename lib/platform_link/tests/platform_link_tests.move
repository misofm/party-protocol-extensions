// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

#[test_only]
module platform_link::platform_link_tests;

// === Imports ===

use std::bcs;
use std::unit_test::assert_eq;
use sui::event;
use platform_link::platform_link as pl;

public struct FooData has copy, drop, store { v: u64 }
public struct BarData has copy, drop, store { v: u64 }
public struct BlobData has copy, drop, store { bytes: vector<u8> }

#[test]
fun wraps_reads_and_limits_are_silent() {
    let link = pl::new(FooData { v: 42 });
    assert_eq!(link.data().v, 42);
    assert_eq!(pl::max_identifier_length(), 256);
    assert_eq!(pl::max_url_length(), 2000);
    assert_eq!(event::num_events(), 0);
}

#[test]
fun set_get_borrow_remove_events_and_reads() {
    let ctx = &mut tx_context::dummy();
    let mut uid = object::new(ctx);
    let parent_id = uid.to_inner();
    let first = FooData { v: 1 };
    let second = FooData { v: 2 };

    assert!(!pl::exists_<FooData>(&uid));
    assert!(pl::get<FooData>(&uid).is_none());
    assert_eq!(event::num_events(), 0);

    pl::set(&mut uid, pl::new(first));
    assert!(pl::exists_<FooData>(&uid));
    assert_eq!(pl::borrow<FooData>(&uid).data().v, 1);
    assert_eq!(pl::get<FooData>(&uid).destroy_some().data().v, 1);
    assert_eq!(event::num_events(), 1);

    let set_events = event::events_by_type<pl::PlatformLinkSetEvent<FooData>>();
    let (event_parent_id, event_data) = pl::set_event_fields(&set_events[0]);
    assert_eq!(event_parent_id, parent_id);
    assert_eq!(event_data.v, 1);

    pl::set(&mut uid, pl::new(second));
    assert_eq!(pl::borrow<FooData>(&uid).data().v, 2);
    assert_eq!(pl::get<FooData>(&uid).destroy_some().data().v, 2);
    assert_eq!(event::num_events(), 2);
    let set_events = event::events_by_type<pl::PlatformLinkSetEvent<FooData>>();
    let (event_parent_id, event_data) = pl::set_event_fields(&set_events[1]);
    assert_eq!(event_parent_id, parent_id);
    assert_eq!(event_data.v, 2);

    let removed = pl::remove<FooData>(&mut uid);
    assert_eq!(removed.data().v, 2);
    assert!(!pl::exists_<FooData>(&uid));
    assert_eq!(event::num_events(), 3);
    let removed_events = event::events_by_type<pl::PlatformLinkRemovedEvent<FooData>>();
    assert_eq!(pl::removed_event_fields(&removed_events[0]), parent_id);

    assert!(pl::get<FooData>(&uid).is_none());
    assert!(!pl::exists_<FooData>(&uid));
    assert_eq!(event::num_events(), 3);
    uid.delete();
}

#[test]
fun clear_absent_repeated_is_silent_and_present_emits() {
    let ctx = &mut tx_context::dummy();
    let mut uid = object::new(ctx);
    let parent_id = uid.to_inner();

    pl::clear<FooData>(&mut uid);
    pl::clear<FooData>(&mut uid);
    assert_eq!(event::num_events(), 0);

    let data = FooData { v: 7 };
    pl::set(&mut uid, pl::new(data));
    assert_eq!(event::num_events(), 1);
    pl::clear<FooData>(&mut uid);
    assert!(!pl::exists_<FooData>(&uid));
    assert_eq!(event::num_events(), 2);

    let removed_events = event::events_by_type<pl::PlatformLinkRemovedEvent<FooData>>();
    assert_eq!(removed_events.length(), 1);
    assert_eq!(pl::removed_event_fields(&removed_events[0]), parent_id);

    pl::clear<FooData>(&mut uid);
    assert_eq!(event::num_events(), 2);
    uid.delete();
}

#[test]
fun equal_replacement_is_silent_but_change_emits() {
    let ctx = &mut tx_context::dummy();
    let mut uid = object::new(ctx);
    let data = FooData { v: 9 };

    pl::set(&mut uid, pl::new(data));
    pl::set(&mut uid, pl::new(data));
    assert_eq!(event::num_events(), 1);
    assert_eq!(pl::borrow<FooData>(&uid).data().v, 9);

    let changed = FooData { v: 10 };
    pl::set(&mut uid, pl::new(changed));
    assert_eq!(event::num_events(), 2);
    let set_events = event::events_by_type<pl::PlatformLinkSetEvent<FooData>>();
    let (_, event_data) = pl::set_event_fields(&set_events[1]);
    assert_eq!(event_data.v, 10);

    pl::clear<FooData>(&mut uid);
    uid.delete();
}

#[test]
fun typed_parent_and_type_streams_are_distinct() {
    let ctx = &mut tx_context::dummy();
    let mut foo_uid_a = object::new(ctx);
    let mut foo_uid_b = object::new(ctx);
    let foo_parent_a = foo_uid_a.to_inner();
    let foo_parent_b = foo_uid_b.to_inner();
    pl::set(&mut foo_uid_a, pl::new(FooData { v: 1 }));
    pl::set(&mut foo_uid_b, pl::new(FooData { v: 2 }));
    pl::set(&mut foo_uid_a, pl::new(BarData { v: 3 }));

    let foo_events = event::events_by_type<pl::PlatformLinkSetEvent<FooData>>();
    let bar_events = event::events_by_type<pl::PlatformLinkSetEvent<BarData>>();
    assert_eq!(foo_events.length(), 2);
    assert_eq!(bar_events.length(), 1);
    let (parent_id, data) = pl::set_event_fields(&foo_events[0]);
    assert_eq!(parent_id, foo_parent_a);
    assert_eq!(data.v, 1);
    let (parent_id, data) = pl::set_event_fields(&foo_events[1]);
    assert_eq!(parent_id, foo_parent_b);
    assert_eq!(data.v, 2);
    let (parent_id, data) = pl::set_event_fields(&bar_events[0]);
    assert_eq!(parent_id, foo_parent_a);
    assert_eq!(data.v, 3);

    pl::clear<FooData>(&mut foo_uid_a);
    pl::clear<FooData>(&mut foo_uid_b);
    pl::clear<BarData>(&mut foo_uid_a);
    foo_uid_a.delete();
    foo_uid_b.delete();
}

#[test]
fun empty_payload_is_not_absence() {
    let ctx = &mut tx_context::dummy();
    let mut uid = object::new(ctx);
    pl::clear<vector<u8>>(&mut uid);
    assert!(!pl::exists_<vector<u8>>(&uid));
    assert_eq!(event::num_events(), 0);

    let empty: vector<u8> = vector[];
    pl::set(&mut uid, pl::new(empty));
    assert!(pl::exists_<vector<u8>>(&uid));
    assert_eq!(event::num_events(), 1);
    let set_events = event::events_by_type<pl::PlatformLinkSetEvent<vector<u8>>>();
    let (_, event_data) = pl::set_event_fields(&set_events[0]);
    assert_eq!(event_data, vector[]);
    // 32-byte parent ID + 1-byte empty vector length.
    assert_eq!(bcs::to_bytes(&set_events[0]).length(), 33);

    let _ = pl::remove<vector<u8>>(&mut uid);
    assert!(!pl::exists_<vector<u8>>(&uid));
    assert_eq!(event::num_events(), 2);
    uid.delete();
}

#[test]
fun large_payload_is_emitted_in_full() {
    let ctx = &mut tx_context::dummy();
    let mut uid = object::new(ctx);
    let data = BlobData { bytes: vector::tabulate!(131072, |_| 7u8) };
    pl::set(&mut uid, pl::new(data));

    let set_events = event::events_by_type<pl::PlatformLinkSetEvent<BlobData>>();
    let (_, event_data) = pl::set_event_fields(&set_events[0]);
    assert_eq!(event_data.bytes.length(), 131072);
    // 32-byte parent ID + 3-byte ULEB128 length + payload.
    assert_eq!(bcs::to_bytes(&set_events[0]).length(), 131107);

    pl::set(&mut uid, pl::new(BlobData { bytes: vector[8u8] }));
    let changed = event::events_by_type<pl::PlatformLinkSetEvent<BlobData>>();
    let (_, event_data) = pl::set_event_fields(&changed[1]);
    assert_eq!(event_data.bytes, vector[8u8]);
    assert_eq!(pl::borrow<BlobData>(&uid).data().bytes, vector[8u8]);
    pl::clear<BlobData>(&mut uid);
    let removed = event::events_by_type<pl::PlatformLinkRemovedEvent<BlobData>>();
    assert_eq!(bcs::to_bytes(&removed[0]).length(), 32);
    uid.delete();
}

#[test, expected_failure(abort_code = pl::ENoLink)]
fun borrow_missing_aborts() {
    let ctx = &mut tx_context::dummy();
    let uid = object::new(ctx);
    let _ = pl::borrow<FooData>(&uid);
    abort
}

#[test, expected_failure(abort_code = pl::ENoLink)]
fun remove_missing_aborts() {
    let ctx = &mut tx_context::dummy();
    let mut uid = object::new(ctx);
    let _ = pl::remove<FooData>(&mut uid);
    abort
}
