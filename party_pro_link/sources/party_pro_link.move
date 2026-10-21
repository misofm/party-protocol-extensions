// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Professional `platform_link` payloads: an artist's website, booking, management,
/// publisher and label pages, EPK, and creator-support platforms (Patreon, Substack, Ko-fi).
///
/// A website, booking page or EPK has no reconstructable handle (the URL is the identity),
/// so those store a full `url`. The creator platforms store just a handle, with the URL
/// rebuilt client-side.
module party_pro_link::party_pro_link;

// === Imports ===

use std::string::String;
use platform_link::platform_link::{Self, PlatformLink};

// === Errors ===

const EEmptyValue: u64 = 0;
const EUrlTooLong: u64 = 1;
const EHandleTooLong: u64 = 2;

// === Structs ===

public struct WebsiteData has copy, drop, store { url: String }
public struct BookingPageData has copy, drop, store { url: String }
public struct ManagementPageData has copy, drop, store { url: String }
public struct PublisherPageData has copy, drop, store { url: String }
public struct LabelPageData has copy, drop, store { url: String }
/// An electronic press kit.
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

public fun website(url: String): PlatformLink<WebsiteData> {
    validate_url(&url);
    platform_link::new(WebsiteData { url })
}

public fun booking_page(url: String): PlatformLink<BookingPageData> {
    validate_url(&url);
    platform_link::new(BookingPageData { url })
}

public fun management_page(url: String): PlatformLink<ManagementPageData> {
    validate_url(&url);
    platform_link::new(ManagementPageData { url })
}

public fun publisher_page(url: String): PlatformLink<PublisherPageData> {
    validate_url(&url);
    platform_link::new(PublisherPageData { url })
}

public fun label_page(url: String): PlatformLink<LabelPageData> {
    validate_url(&url);
    platform_link::new(LabelPageData { url })
}

public fun epk(url: String): PlatformLink<EpkData> {
    validate_url(&url);
    platform_link::new(EpkData { url })
}

public fun patreon(handle: String): PlatformLink<PatreonData> {
    validate_handle(&handle);
    platform_link::new(PatreonData { handle })
}

public fun substack(subdomain: String): PlatformLink<SubstackData> {
    validate_handle(&subdomain);
    platform_link::new(SubstackData { subdomain })
}

public fun kofi(handle: String): PlatformLink<KofiData> {
    validate_handle(&handle);
    platform_link::new(KofiData { handle })
}

// === View Functions ===

public fun website_url(self: &WebsiteData): String {
    self.url
}

public fun booking_url(self: &BookingPageData): String {
    self.url
}

public fun management_url(self: &ManagementPageData): String {
    self.url
}

public fun publisher_url(self: &PublisherPageData): String {
    self.url
}

public fun label_url(self: &LabelPageData): String {
    self.url
}

public fun epk_url(self: &EpkData): String {
    self.url
}

public fun patreon_handle(self: &PatreonData): String {
    self.handle
}

public fun substack_subdomain(self: &SubstackData): String {
    self.subdomain
}

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
