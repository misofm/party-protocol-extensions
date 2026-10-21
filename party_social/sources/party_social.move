// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Social-platform `platform_link` payloads: one `...Data` handle wrapper per network, so a
/// party carries one independent link per network.
///
/// Only the native handle is stored; clients rebuild the profile URL (e.g.
/// `x.com/{handle}`), so a platform reshaping its URLs needs no on-chain change. Handle
/// format rules change over time and belong in the app layer.
module party_social::party_social;

// === Imports ===

use std::string::String;
use platform_link::platform_link::{Self, PlatformLink};

// === Errors ===

const EEmptyHandle: u64 = 0;
const EHandleTooLong: u64 = 1;

// === Structs ===

/// An X (formerly Twitter) handle, without the leading `@`.
public struct XData has copy, drop, store { handle: String }
public struct InstagramData has copy, drop, store { handle: String }
/// A Threads handle, without the leading `@`.
public struct ThreadsData has copy, drop, store { handle: String }
/// A TikTok handle, without the leading `@`.
public struct TikTokData has copy, drop, store { handle: String }
/// A YouTube handle or channel identifier.
public struct YouTubeData has copy, drop, store { handle: String }
/// A Discord server-invite code (the `{code}` in `discord.gg/{code}`).
public struct DiscordData has copy, drop, store { handle: String }
/// A Telegram username or channel (the `{name}` in `t.me/{name}`).
public struct TelegramData has copy, drop, store { handle: String }
/// A Reddit username (the `{name}` in `reddit.com/user/{name}`).
public struct RedditData has copy, drop, store { handle: String }
public struct TwitchData has copy, drop, store { handle: String }
/// A Facebook page username or id.
public struct FacebookData has copy, drop, store { handle: String }

// === Method Aliases ===

public use fun x_handle as XData.handle;
public use fun instagram_handle as InstagramData.handle;
public use fun threads_handle as ThreadsData.handle;
public use fun tiktok_handle as TikTokData.handle;
public use fun youtube_handle as YouTubeData.handle;
public use fun discord_handle as DiscordData.handle;
public use fun telegram_handle as TelegramData.handle;
public use fun reddit_handle as RedditData.handle;
public use fun twitch_handle as TwitchData.handle;
public use fun facebook_handle as FacebookData.handle;

// === Public Functions ===

public fun x(handle: String): PlatformLink<XData> {
    validate_handle(&handle);
    platform_link::new(XData { handle })
}

public fun instagram(handle: String): PlatformLink<InstagramData> {
    validate_handle(&handle);
    platform_link::new(InstagramData { handle })
}

public fun threads(handle: String): PlatformLink<ThreadsData> {
    validate_handle(&handle);
    platform_link::new(ThreadsData { handle })
}

public fun tiktok(handle: String): PlatformLink<TikTokData> {
    validate_handle(&handle);
    platform_link::new(TikTokData { handle })
}

public fun youtube(handle: String): PlatformLink<YouTubeData> {
    validate_handle(&handle);
    platform_link::new(YouTubeData { handle })
}

public fun discord(handle: String): PlatformLink<DiscordData> {
    validate_handle(&handle);
    platform_link::new(DiscordData { handle })
}

public fun telegram(handle: String): PlatformLink<TelegramData> {
    validate_handle(&handle);
    platform_link::new(TelegramData { handle })
}

public fun reddit(handle: String): PlatformLink<RedditData> {
    validate_handle(&handle);
    platform_link::new(RedditData { handle })
}

public fun twitch(handle: String): PlatformLink<TwitchData> {
    validate_handle(&handle);
    platform_link::new(TwitchData { handle })
}

public fun facebook(handle: String): PlatformLink<FacebookData> {
    validate_handle(&handle);
    platform_link::new(FacebookData { handle })
}

// === View Functions ===

public fun x_handle(self: &XData): String {
    self.handle
}

public fun instagram_handle(self: &InstagramData): String {
    self.handle
}

public fun threads_handle(self: &ThreadsData): String {
    self.handle
}

public fun tiktok_handle(self: &TikTokData): String {
    self.handle
}

public fun youtube_handle(self: &YouTubeData): String {
    self.handle
}

public fun discord_handle(self: &DiscordData): String {
    self.handle
}

public fun telegram_handle(self: &TelegramData): String {
    self.handle
}

public fun reddit_handle(self: &RedditData): String {
    self.handle
}

public fun twitch_handle(self: &TwitchData): String {
    self.handle
}

public fun facebook_handle(self: &FacebookData): String {
    self.handle
}

// === Private Functions ===

fun validate_handle(handle: &String) {
    assert!(!handle.is_empty(), EEmptyHandle);
    assert!(handle.length() <= platform_link::max_identifier_length(), EHandleTooLong);
}
