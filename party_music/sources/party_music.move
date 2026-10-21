// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Artist-level `platform_link` payloads for a party's pages on streaming and music sites.
///
/// Distinct from the release-level (album/track) payloads of the DSP-link extension. Only
/// the native id is stored; clients rebuild the URL, so a platform reshaping its URLs needs
/// no on-chain change.
module party_music::party_music;

// === Imports ===

use std::string::String;
use platform_link::platform_link::{Self, PlatformLink};

// === Errors ===

const EEmptyId: u64 = 0;
const EIdTooLong: u64 = 1;

// === Structs ===

/// A Spotify artist id (the id in `open.spotify.com/artist/{id}`).
public struct SpotifyData has copy, drop, store { artist_id: String }
/// A Bandcamp subdomain (the `{name}` in `{name}.bandcamp.com`).
public struct BandcampData has copy, drop, store { subdomain: String }
/// A SoundCloud username (the `{name}` in `soundcloud.com/{name}`).
public struct SoundCloudData has copy, drop, store { username: String }
/// An Apple Music artist id (the numeric id in `music.apple.com/artist/{id}`).
public struct AppleMusicData has copy, drop, store { artist_id: String }
/// A Deezer artist id (the id in `deezer.com/artist/{id}`).
public struct DeezerData has copy, drop, store { artist_id: String }
/// A Tidal artist id (the id in `tidal.com/artist/{id}`).
public struct TidalData has copy, drop, store { artist_id: String }
/// An Amazon Music artist id (the id in `music.amazon.com/artists/{id}`).
public struct AmazonMusicData has copy, drop, store { artist_id: String }
/// An Audiomack username (the `{name}` in `audiomack.com/{name}`).
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

public fun spotify_artist_id(self: &SpotifyData): String {
    self.artist_id
}

public fun bandcamp_subdomain(self: &BandcampData): String {
    self.subdomain
}

public fun soundcloud_username(self: &SoundCloudData): String {
    self.username
}

public fun apple_music_artist_id(self: &AppleMusicData): String {
    self.artist_id
}

public fun deezer_artist_id(self: &DeezerData): String {
    self.artist_id
}

public fun tidal_artist_id(self: &TidalData): String {
    self.artist_id
}

public fun amazon_music_artist_id(self: &AmazonMusicData): String {
    self.artist_id
}

public fun audiomack_username(self: &AudiomackData): String {
    self.username
}

// === Private Functions ===

fun validate_id(id: &String) {
    assert!(!id.is_empty(), EEmptyId);
    assert!(id.length() <= platform_link::max_identifier_length(), EIdTooLong);
}
