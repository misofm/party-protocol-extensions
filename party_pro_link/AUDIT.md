# Security Audit — `party_pro_link`
Audited at `067a532492f3db79a100883e994f54731cacc719` (2026-10-21). Scope: `party_pro_link`, module `party_pro_link::party_pro_link`.

## What it does
Pure payload package: validated `Data` types wrapped as `PlatformLink<Data>` for `party_platform_link`. Six URL payloads and three handle payloads. See [README](README.md).

## Trust model
- No `Party`, cap, storage or events. Constructors are permissionless and pure.
- Every `Data` struct has private fields, so the validating constructor is the only way to build one. Copies of an existing value (`copy`) are always valid.
- Authorization for attaching a link lives in `party_platform_link`.

## Findings

**PRL-1 — Medium — Open.** `platform_link` is a local-path dependency (`Move.toml:8`). Builds link it to the recorded publication, whose set event carries no payload (`lib/platform_link/AUDIT.md` PL-1). The payload types published here would then be `PlatformLink` values of that old package, and links of these types would emit payload-free events. Fix: republish `platform_link` first and build this package against the new address.

**PRL-2 — Info — Accepted.** Validation is only non-empty plus a byte-length backstop (`party_pro_link.move:129-137`). There is no character set or format check and no proof of account ownership. The README says the same. URL payloads are stored verbatim, so clients must check the scheme and sanitize before linking.

**PRL-3 — Info — Open.** The README's Errors section says that reading or removing a link that was never stored aborts `ENoLink`, "surfaced through `party_platform_link`". That is wrong: `party_platform_link` never calls `remove` or `borrow`, `link` returns `Option`, and `clear_link` is silent when nothing is stored. Fix: delete the sentence.

## Checked, no finding
- Every constructor calls the validator before `platform_link::new`. Limits come from `platform_link::max_identifier_length()` (256) and `max_url_length()` (2000).
- Each platform is a distinct `Data` type, so its `PlatformLinkKey<Data>` is distinct from every other platform's, here and in sibling packages.
- Error codes are plain `u64` constants; all are reachable and tested.

## Verification
- `sui move test --coverage` (sui 1.82.1): 6/6 pass; module coverage 100.00%.
- Strict lint builds pass for `-e mainnet` and `-e testnet`.
