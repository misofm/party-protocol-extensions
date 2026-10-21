// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Professional / industry payloads for the `platform_link` primitive: an
/// artist's own website, booking/management/publisher/label pages, EPK, and
/// creator-support platforms (Patreon, Substack, Ko-fi).
///
/// Two shapes here. A website / booking page / EPK has **no reconstructable
/// handle** — the URL *is* the identity — so those store a full `url`. The
/// creator platforms have a handle like the social/music payloads and store just
/// that, with the URL rebuilt client-side. All validated non-empty plus the
/// shared max-length backstops (`platform_link::max_identifier_length()` /
/// `max_url_length()`).
module party_pro_link::party_pro_link;

// === Imports ===

use std::string::String;
use platform_link::platform_link::{Self, PlatformLink};

// === Errors ===

/// The value was empty.
const EEmptyValue: u64 = 0;
/// The url exceeded the maximum length.
const EUrlTooLong: u64 = 1;
/// The handle exceeded the maximum length.
const EHandleTooLong: u64 = 2;

// === Structs ===

/// The artist's official website URL.
public struct WebsiteData has copy, drop, store { url: String }
/// A booking-agent page URL.
public struct BookingPageData has copy, drop, store { url: String }
/// A management-company page URL.
public struct ManagementPageData has copy, drop, store { url: String }
/// A publisher page URL.
public struct PublisherPageData has copy, drop, store { url: String }
/// A label page URL.
public struct LabelPageData has copy, drop, store { url: String }
/// An electronic press kit (EPK) URL.
public struct EpkData has copy, drop, store { url: String }

/// A Patreon handle (the `{name}` in `patreon.com/{name}`).
public struct PatreonData has copy, drop, store { handle: String }
/// A Substack subdomain (the `{name}` in `{name}.substack.com`).
public struct SubstackData has copy, drop, store { subdomain: String }
/// A Ko-fi handle (the `{name}` in `ko-fi.com/{name}`).
public struct KofiData has copy, drop, store { handle: String }

// === Method Aliases ===

public use fun website_url as WebsiteData.url;
public use fun booking_url as BookingPageData.url;
public use fun management_url as ManagementPageData.url;
public use fun publisher_url as PublisherPageData.url;
public use fun label_url as LabelPageData.url;
public use fun epk_url as EpkData.url;
public use fun patreon_handle as PatreonData.handle;
public use fun substack_subdomain as SubstackData.subdomain;
public use fun kofi_handle as KofiData.handle;

// === Public Functions ===

/// Builds a website link from a full URL. Aborts if empty or too long.
public fun website(url: String): PlatformLink<WebsiteData> {
    validate_url(&url);
    platform_link::new(WebsiteData { url })
}

/// Builds a booking-page link from a full URL. Aborts if empty or too long.
public fun booking_page(url: String): PlatformLink<BookingPageData> {
    validate_url(&url);
    platform_link::new(BookingPageData { url })
}

/// Builds a management-page link from a full URL. Aborts if empty or too long.
public fun management_page(url: String): PlatformLink<ManagementPageData> {
    validate_url(&url);
    platform_link::new(ManagementPageData { url })
}

/// Builds a publisher-page link from a full URL. Aborts if empty or too long.
public fun publisher_page(url: String): PlatformLink<PublisherPageData> {
    validate_url(&url);
    platform_link::new(PublisherPageData { url })
}

/// Builds a label-page link from a full URL. Aborts if empty or too long.
public fun label_page(url: String): PlatformLink<LabelPageData> {
    validate_url(&url);
    platform_link::new(LabelPageData { url })
}

/// Builds an EPK link from a full URL. Aborts if empty or too long.
public fun epk(url: String): PlatformLink<EpkData> {
    validate_url(&url);
    platform_link::new(EpkData { url })
}

/// Builds a Patreon link from a handle. Aborts if empty or too long.
public fun patreon(handle: String): PlatformLink<PatreonData> {
    validate_handle(&handle);
    platform_link::new(PatreonData { handle })
}

/// Builds a Substack link from a subdomain. Aborts if empty or too long.
public fun substack(subdomain: String): PlatformLink<SubstackData> {
    validate_handle(&subdomain);
    platform_link::new(SubstackData { subdomain })
}

/// Builds a Ko-fi link from a handle. Aborts if empty or too long.
public fun kofi(handle: String): PlatformLink<KofiData> {
    validate_handle(&handle);
    platform_link::new(KofiData { handle })
}

// === View Functions ===

/// The `url` of a `WebsiteData`.
public fun website_url(self: &WebsiteData): String {
    self.url
}

/// The `url` of a `BookingPageData`.
public fun booking_url(self: &BookingPageData): String {
    self.url
}

/// The `url` of a `ManagementPageData`.
public fun management_url(self: &ManagementPageData): String {
    self.url
}

/// The `url` of a `PublisherPageData`.
public fun publisher_url(self: &PublisherPageData): String {
    self.url
}

/// The `url` of a `LabelPageData`.
public fun label_url(self: &LabelPageData): String {
    self.url
}

/// The `url` of a `EpkData`.
public fun epk_url(self: &EpkData): String {
    self.url
}

/// The `handle` of a `PatreonData`.
public fun patreon_handle(self: &PatreonData): String {
    self.handle
}

/// The `subdomain` of a `SubstackData`.
public fun substack_subdomain(self: &SubstackData): String {
    self.subdomain
}

/// The `handle` of a `KofiData`.
public fun kofi_handle(self: &KofiData): String {
    self.handle
}

// === Private Functions ===

fun validate_url(url: &String) {
    assert!(!url.is_empty(), EEmptyValue);
    assert!(url.length() <= platform_link::max_url_length(), EUrlTooLong);
}

fun validate_handle(handle: &String) {
    assert!(!handle.is_empty(), EEmptyValue);
    assert!(handle.length() <= platform_link::max_identifier_length(), EHandleTooLong);
}
