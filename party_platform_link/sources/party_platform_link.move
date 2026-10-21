// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

module party_platform_link::party_platform_link;

// === Imports ===

use miso_party::party::{Party, PartyAdminCap};
use platform_link::platform_link::{Self, PlatformLink};

// === Public Functions ===

public fun set_link<Data: copy + drop + store>(
    party: &mut Party,
    cap: &PartyAdminCap,
    link: PlatformLink<Data>,
) {
    platform_link::set(party.uid_mut(cap), link);
}

public fun clear_link<Data: copy + drop + store>(party: &mut Party, cap: &PartyAdminCap) {
    let uid = party.uid_mut(cap);
    if (platform_link::exists_<Data>(uid)) {
        platform_link::clear<Data>(uid);
    }
}

// === View Functions ===

public fun has_link<Data: copy + drop + store>(party: &Party): bool {
    platform_link::exists_<Data>(party.uid())
}

public fun link<Data: copy + drop + store>(party: &Party): Option<PlatformLink<Data>> {
    platform_link::get<Data>(party.uid())
}
