// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Attaches `PlatformLink<Data>` records to a `Party` — one independent link per
/// platform type (`set_link<XData>`, `set_link<SpotifyData>`, …), each in its own
/// dynamic field keyed by `Data`. Adding one platform never rewrites another's,
/// and a new platform needs no change here.
///
/// This one module serves every platform (social, music, anything) because it is
/// generic over `Data`; the payload types live in their own small packages
/// (`party_social`, `party_music`, …). All writes are gated by the
/// `PartyAdminCap` via `uid_mut`; views are permissionless. Events come from the
/// primitive: `PlatformLinkSetEvent<Data>` (party ID + full payload) and
/// `PlatformLinkRemovedEvent<Data>` (party ID); this module emits none itself.
module party_platform_link::party_platform_link;

use miso_party::party::{Party, PartyAdminCap};
use platform_link::platform_link::{Self, PlatformLink};

// === Write API ===

/// Sets (or replaces) a platform's link on the party. The primitive emits one
/// `PlatformLinkSetEvent<Data>` with the new payload; an equal replacement is
/// silent.
public fun set_link<Data: copy + drop + store>(
    self: &mut Party,
    cap: &PartyAdminCap,
    link: PlatformLink<Data>,
) {
    platform_link::set(self.uid_mut(cap), link);
}

/// Clears a platform's link from the party. Cap authorization is checked before
/// the existence check. A present link delegates to the primitive, which emits
/// one `PlatformLinkRemovedEvent<Data>`; absent and repeated clears are silent.
public fun clear_link<Data: copy + drop + store>(self: &mut Party, cap: &PartyAdminCap) {
    // Cap-gate first: a wrong cap must abort even when no link is present, so
    // authorization never depends on state the caller can't be sure of.
    let uid = self.uid_mut(cap);
    if (platform_link::exists_<Data>(uid)) {
        platform_link::clear<Data>(uid);
    }
}

// === Views ===

/// Whether the party has a link for this platform.
public fun has_link<Data: copy + drop + store>(self: &Party): bool {
    platform_link::exists_<Data>(self.uid())
}

/// The party's link for this platform, if set.
public fun link<Data: copy + drop + store>(self: &Party): Option<PlatformLink<Data>> {
    platform_link::get<Data>(self.uid())
}
