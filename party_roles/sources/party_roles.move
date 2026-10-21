// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

/// Artist-type roles for a party: what kind of act it is (artist, producer, DJ, band,
/// label, ...). A party can hold several.
///
/// `ArtistRole` is a closed enum with a `Custom` escape hatch, mirroring
/// `composition_party_role`. Duplicate, missing and over-max writes abort with
/// `typed_set`'s error codes.
module party_roles::party_roles;

// === Imports ===

use std::string::String;
use sui::event::emit;
use miso_party::party::{Party, PartyAdminCap};
use typed_set::typed_set as set;

// === Errors ===

const EEmptyCustomName: u64 = 0;
const ECustomNameTooLong: u64 = 1;

// === Constants ===

/// In bytes.
const MAX_CUSTOM_NAME_LENGTH: u64 = 60;
const MAX_ROLES: u64 = 12;

// === Structs ===

/// Stored as a `VecSet<ArtistRole>` through `typed_set`.
public struct RolesKey() has copy, drop, store;

// === Enums ===

public enum ArtistRole has copy, drop, store {
    Artist,
    Producer,
    Dj,
    Composer,
    Songwriter,
    Band,
    Label,
    Collective,
    /// Prefer a canonical variant when one fits.
    Custom(String),
}

// === Events ===

public struct RoleAddedEvent has copy, drop {
    party_id: ID,
    role: ArtistRole,
}

public struct RoleRemovedEvent has copy, drop {
    party_id: ID,
    role: ArtistRole,
}

public struct RolesClearedEvent has copy, drop {
    party_id: ID,
}

// === Method Aliases ===

public use fun role_name as ArtistRole.name;

// === Public Functions ===

public fun artist(): ArtistRole { ArtistRole::Artist }

public fun producer(): ArtistRole { ArtistRole::Producer }

public fun dj(): ArtistRole { ArtistRole::Dj }

public fun composer(): ArtistRole { ArtistRole::Composer }

public fun songwriter(): ArtistRole { ArtistRole::Songwriter }

public fun band(): ArtistRole { ArtistRole::Band }

public fun label(): ArtistRole { ArtistRole::Label }

public fun collective(): ArtistRole { ArtistRole::Collective }

public fun custom(name: String): ArtistRole {
    assert!(!name.is_empty(), EEmptyCustomName);
    assert!(name.length() <= MAX_CUSTOM_NAME_LENGTH, ECustomNameTooLong);
    ArtistRole::Custom(name)
}

public fun add_role(self: &mut Party, cap: &PartyAdminCap, role: ArtistRole) {
    let party_id = object::id(self);
    set::add(self.uid_mut(cap), RolesKey(), role, MAX_ROLES);
    emit(RoleAddedEvent { party_id, role });
}

/// The whole field is dropped when the last role leaves.
public fun remove_role(self: &mut Party, cap: &PartyAdminCap, role: ArtistRole) {
    let party_id = object::id(self);
    set::remove(self.uid_mut(cap), RolesKey(), role);
    emit(RoleRemovedEvent { party_id, role });
}

/// No-op if none is set.
public fun clear_roles(self: &mut Party, cap: &PartyAdminCap) {
    let party_id = object::id(self);
    let uid = self.uid_mut(cap);
    if (set::exists(uid, RolesKey())) {
        set::clear<RolesKey, ArtistRole>(uid, RolesKey());
        emit(RolesClearedEvent { party_id });
    }
}

// === View Functions ===

public fun has_roles(self: &Party): bool {
    set::exists(self.uid(), RolesKey())
}

public fun has_role(self: &Party, role: ArtistRole): bool {
    set::contains(self.uid(), RolesKey(), &role)
}

public fun roles(self: &Party): vector<ArtistRole> {
    set::keys(self.uid(), RolesKey())
}

public fun role_name(self: &ArtistRole): String {
    match (self) {
        ArtistRole::Artist => b"Artist".to_string(),
        ArtistRole::Producer => b"Producer".to_string(),
        ArtistRole::Dj => b"DJ".to_string(),
        ArtistRole::Composer => b"Composer".to_string(),
        ArtistRole::Songwriter => b"Songwriter".to_string(),
        ArtistRole::Band => b"Band".to_string(),
        ArtistRole::Label => b"Label".to_string(),
        ArtistRole::Collective => b"Collective".to_string(),
        ArtistRole::Custom(name) => *name,
    }
}

// === Test Functions ===

#[test_only]
public fun added_event_fields(event: &RoleAddedEvent): (ID, ArtistRole) {
    (event.party_id, event.role)
}

#[test_only]
public fun removed_event_fields(event: &RoleRemovedEvent): (ID, ArtistRole) {
    (event.party_id, event.role)
}

#[test_only]
public fun cleared_event_fields(event: &RolesClearedEvent): ID {
    event.party_id
}
