# Release Audit — `platform_link`

**Repository:** `https://github.com/misofm/party-protocol-extensions`
**Audit target:** `main`
**Reviewed:** 2026-09-11 with `sui 1.79.0`
**Verification re-run:** 2026-10-21 with `sui 1.82.1`, after the house-style pass

## Verdict

Release-ready. No security or correctness findings remain.

## Implementation reviewed

`platform_link` is a protocol-agnostic primitive. It wraps a payload as
`PlatformLink<Data>` and stores at most one value per `Data` type under any
caller-supplied `UID`, using the phantom-typed `PlatformLinkKey<Data>`. It
implements set/replace, optional read, borrow, remove, and idempotent clear.
Changed set operations emit a typed event with the parent ID and the full
payload; remove and present clear emit the parent ID. Equal set replacements
are silent. It contains no Party, capability,
Vault, Action, plugin, or fund logic; authorization belongs to its caller.
Identifier and URL backstops are exactly 256 and 2000 bytes.

## Dependency provenance

The manifest has no explicit dependency. `Move.lock` resolves the Sui
framework for both Testnet and Mainnet at exact revision
`719fb2960ccfbf9f4d33041f8ea5146d30671696`. There are no local-path, branch,
or floating Git dependencies.

## Verification

- Package tests: **9/9**, including **2** expected-failure paths (`borrow` and
  `remove` when absent), exact set/replace/remove and clear event assertions,
  typed parent/type streams, empty payload handling, and a 131072-byte payload
  emitted in full.
- Production instruction coverage: **100.00%**.
- Shared-Party workflow: not applicable; this primitive accepts a `UID` and
  owns no host object.
- Repository aggregate (re-run 2026-10-21): **146/146** tests across the 11
  packages with zero warnings, strict Mainnet and Testnet builds; all 11
  production modules at **100.00%**.
- Fresh copies without `Published.toml` or `Move.lock` build strictly for both
  networks.

## Published metadata

The retained `Published.toml` is the sole record of the prior immutable Testnet package id;
it is not repeated here.
It is historical deployment metadata and does not attest to pending source.
Fresh immutable publication uses the admin CLI with `--allow-republish`; only
after confirmed success may it replace the target network block.
