// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

/// Attaches `PlatformLink<Data>` records to a `Party`, one independent dynamic field per
/// platform type, so adding one platform never rewrites another's.
///
/// Generic over `Data`; the payload types live in their own small packages (`party_social`,
/// `party_music`, ...). Events come from the `platform_link` primitive; this module emits
/// none itself.
module party_platform_link::party_platform_link;

// === Imports ===

use miso_party::party::{Party, PartyAdminCap};
use platform_link::platform_link::{Self, PlatformLink};

// === Public Functions ===

/// An equal replacement is silent.
public fun set_link<Data: copy + drop + store>(
    self: &mut Party,
    cap: &PartyAdminCap,
    link: PlatformLink<Data>,
) {
    platform_link::set(self.uid_mut(cap), link);
}

/// Authorization is checked before existence; absent and repeated clears are silent.
public fun clear_link<Data: copy + drop + store>(self: &mut Party, cap: &PartyAdminCap) {
    let uid = self.uid_mut(cap);
    if (platform_link::exists_<Data>(uid)) {
        platform_link::clear<Data>(uid);
    }
}

// === View Functions ===

public fun has_link<Data: copy + drop + store>(self: &Party): bool {
    platform_link::exists_<Data>(self.uid())
}

public fun link<Data: copy + drop + store>(self: &Party): Option<PlatformLink<Data>> {
    platform_link::get<Data>(self.uid())
}
