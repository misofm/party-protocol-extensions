// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module party_pro_link::party_pro_link_tests;

// === Imports ===

use std::unit_test::assert_eq;
use sui::event;
use party_pro_link::party_pro_link as pro;

#[test]
fun url_based_constructors() {
    let url = b"https://miso.fm".to_string();
    assert_eq!(pro::website(url).data().url(), url);
    let url = b"https://book.example".to_string();
    assert_eq!(pro::booking_page(url).data().url(), url);
    let url = b"https://management.example".to_string();
    assert_eq!(pro::management_page(url).data().url(), url);
    let url = b"https://publisher.example".to_string();
    assert_eq!(pro::publisher_page(url).data().url(), url);
    let url = b"https://epk.example".to_string();
    assert_eq!(pro::epk(url).data().url(), url);
    let url = b"https://label.example".to_string();
    assert_eq!(pro::label_page(url).data().url(), url);
    assert_eq!(event::num_events(), 0);
}

#[test]
fun handle_based_constructors() {
    assert_eq!(pro::patreon(b"miso".to_string()).data().handle(), b"miso".to_string());
    assert_eq!(pro::substack(b"miso".to_string()).data().subdomain(), b"miso".to_string());
    assert_eq!(pro::kofi(b"miso".to_string()).data().handle(), b"miso".to_string());
    assert_eq!(event::num_events(), 0);
}

#[test, expected_failure(abort_code = pro::EEmptyValue)]
fun rejects_empty_website() {
    let _ = pro::website(b"".to_string());
    abort
}

#[test, expected_failure(abort_code = pro::EEmptyValue)]
fun rejects_empty_patreon() {
    let _ = pro::patreon(b"".to_string());
    abort
}

#[test, expected_failure(abort_code = pro::EUrlTooLong)]
fun rejects_overlong_url() {
    // 2001 bytes — one over the shared backstop (platform_link::max_url_length(), 2000).
    let long = vector::tabulate!(2001, |_| 97u8).to_string();
    let _ = pro::website(long);
    abort
}

#[test, expected_failure(abort_code = pro::EHandleTooLong)]
fun rejects_overlong_handle() {
    // 257 bytes — one over the shared backstop (platform_link::max_identifier_length(), 256).
    let long = vector::tabulate!(257, |_| 97u8).to_string();
    let _ = pro::patreon(long);
    abort
}
