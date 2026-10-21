// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

module party_music::party_music;

// === Imports ===

use std::string::String;
use platform_link::platform_link::{Self, PlatformLink};

// === Errors ===

const EEmptyId: u64 = 0;
const EIdTooLong: u64 = 1;

// === Structs ===

public struct SpotifyData has copy, drop, store { artist_id: String }
public struct BandcampData has copy, drop, store { subdomain: String }
public struct SoundCloudData has copy, drop, store { username: String }
public struct AppleMusicData has copy, drop, store { artist_id: String }
public struct DeezerData has copy, drop, store { artist_id: String }
public struct TidalData has copy, drop, store { artist_id: String }
public struct AmazonMusicData has copy, drop, store { artist_id: String }
public struct AudiomackData has copy, drop, store { username: String }

// === Method Aliases ===

public use fun spotify_artist_id as SpotifyData.artist_id;
public use fun bandcamp_subdomain as BandcampData.subdomain;
public use fun soundcloud_username as SoundCloudData.username;
public use fun apple_music_artist_id as AppleMusicData.artist_id;
public use fun deezer_artist_id as DeezerData.artist_id;
public use fun tidal_artist_id as TidalData.artist_id;
public use fun amazon_music_artist_id as AmazonMusicData.artist_id;
public use fun audiomack_username as AudiomackData.username;

// === Public Functions ===

public fun spotify(artist_id: String): PlatformLink<SpotifyData> {
    validate_id(&artist_id);
    platform_link::new(SpotifyData { artist_id })
}

public fun bandcamp(subdomain: String): PlatformLink<BandcampData> {
    validate_id(&subdomain);
    platform_link::new(BandcampData { subdomain })
}

public fun soundcloud(username: String): PlatformLink<SoundCloudData> {
    validate_id(&username);
    platform_link::new(SoundCloudData { username })
}

public fun apple_music(artist_id: String): PlatformLink<AppleMusicData> {
    validate_id(&artist_id);
    platform_link::new(AppleMusicData { artist_id })
}

public fun deezer(artist_id: String): PlatformLink<DeezerData> {
    validate_id(&artist_id);
    platform_link::new(DeezerData { artist_id })
}

public fun tidal(artist_id: String): PlatformLink<TidalData> {
    validate_id(&artist_id);
    platform_link::new(TidalData { artist_id })
}

public fun amazon_music(artist_id: String): PlatformLink<AmazonMusicData> {
    validate_id(&artist_id);
    platform_link::new(AmazonMusicData { artist_id })
}

public fun audiomack(username: String): PlatformLink<AudiomackData> {
    validate_id(&username);
    platform_link::new(AudiomackData { username })
}

// === View Functions ===

public fun spotify_artist_id(data: &SpotifyData): String {
    data.artist_id
}

public fun bandcamp_subdomain(data: &BandcampData): String {
    data.subdomain
}

public fun soundcloud_username(data: &SoundCloudData): String {
    data.username
}

public fun apple_music_artist_id(data: &AppleMusicData): String {
    data.artist_id
}

public fun deezer_artist_id(data: &DeezerData): String {
    data.artist_id
}

public fun tidal_artist_id(data: &TidalData): String {
    data.artist_id
}

public fun amazon_music_artist_id(data: &AmazonMusicData): String {
    data.artist_id
}

public fun audiomack_username(data: &AudiomackData): String {
    data.username
}

// === Private Functions ===

fun validate_id(id: &String) {
    assert!(!id.is_empty(), EEmptyId);
    assert!(id.length() <= platform_link::max_identifier_length(), EIdTooLong);
}
