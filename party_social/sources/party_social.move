// Copyright (c) Miso Labs, Inc.
// SPDX-License-Identifier: FSL-1.1-ALv2

module party_social::party_social;

// === Imports ===

use std::string::String;
use platform_link::platform_link::{Self, PlatformLink};

// === Errors ===

const EEmptyHandle: u64 = 0;
const EHandleTooLong: u64 = 1;

// === Structs ===

public struct XData has copy, drop, store { handle: String }
public struct InstagramData has copy, drop, store { handle: String }
public struct ThreadsData has copy, drop, store { handle: String }
public struct TikTokData has copy, drop, store { handle: String }
public struct YouTubeData has copy, drop, store { handle: String }
public struct DiscordData has copy, drop, store { handle: String }
public struct TelegramData has copy, drop, store { handle: String }
public struct RedditData has copy, drop, store { handle: String }
public struct TwitchData has copy, drop, store { handle: String }
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

public fun x_handle(data: &XData): String {
    data.handle
}

public fun instagram_handle(data: &InstagramData): String {
    data.handle
}

public fun threads_handle(data: &ThreadsData): String {
    data.handle
}

public fun tiktok_handle(data: &TikTokData): String {
    data.handle
}

public fun youtube_handle(data: &YouTubeData): String {
    data.handle
}

public fun discord_handle(data: &DiscordData): String {
    data.handle
}

public fun telegram_handle(data: &TelegramData): String {
    data.handle
}

public fun reddit_handle(data: &RedditData): String {
    data.handle
}

public fun twitch_handle(data: &TwitchData): String {
    data.handle
}

public fun facebook_handle(data: &FacebookData): String {
    data.handle
}

// === Private Functions ===

fun validate_handle(handle: &String) {
    assert!(!handle.is_empty(), EEmptyHandle);
    assert!(handle.length() <= platform_link::max_identifier_length(), EHandleTooLong);
}
