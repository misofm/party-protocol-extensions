# Security Audit — `party_social`
Audited at `067a532492f3db79a100883e994f54731cacc719` (2026-10-21). Scope: `party_social`, module `party_social::party_social`.

## What it does
Pure payload package: validated `Data` types wrapped as `PlatformLink<Data>` for `party_platform_link`. Ten social-network handles. See [README](README.md).

## Trust model
- No `Party`, cap, storage or events. Constructors are permissionless and pure.
- Every `Data` struct has private fields, so the validating constructor is the only way to build one. Copies of an existing value (`copy`) are always valid.
- Authorization for attaching a link lives in `party_platform_link`.

## Findings

**SOC-1 — Medium — Open.** `platform_link` is a local-path dependency (`Move.toml:8`). Builds link it to the recorded publication, whose set event carries no payload (`lib/platform_link/AUDIT.md` PL-1). The payload types published here would then be `PlatformLink` values of that old package, and links of these types would emit payload-free events. Fix: republish `platform_link` first and build this package against the new address.

**SOC-2 — Info — Accepted.** Validation is only non-empty plus a byte-length backstop (`party_social.move:138-141`). There is no character set or format check and no proof of account ownership. The README says the same; clients rebuild URLs from the identifiers and sanitize them.

## Checked, no finding
- Every constructor calls the validator before `platform_link::new`. Limits come from `platform_link::max_identifier_length()` (256).
- Each platform is a distinct `Data` type, so its `PlatformLinkKey<Data>` is distinct from every other platform's, here and in sibling packages.
- Error codes are plain `u64` constants; all are reachable and tested.

## Verification
- `sui move test --coverage` (sui 1.82.1): 5/5 pass; module coverage 100.00%.
- Strict lint builds pass for `-e mainnet` and `-e testnet`.
