# Release Audit — `party_platform_link`

**Repository:** `https://github.com/misofm/party-protocol-extensions`
**Audit target:** `main`
**Reviewed:** 2026-09-11 with `sui 1.79.0-46f18562f1f5`
**Verification re-run:** 2026-10-21 with `sui 1.82.1`, after the house-style pass

## Verdict

Release-ready. No security or correctness findings remain.

## Implementation reviewed

`party_platform_link` is the state-attaching bridge for pure platform payloads.
It generically sets/replaces or clears one `PlatformLink<Data>` dynamic field on
a Party, gates writes with the matching `PartyAdminCap`, and provides
permissionless optional reads. The primitive owns the
`PlatformLinkSetEvent<Data>` (party ID + payload) and
`PlatformLinkRemovedEvent<Data>` (party ID) emissions for insertions, changed
replacements, and present clears; equal replacements are silent. The wrapper
declares no events. Clear authenticates before its
absent-state no-op. The package adds no payload validation, funds, Vault
borrowing, Action logic, or entry automation.

## Exact manifest pins

| Dependency | Kind | Location | Mode |
|---|---|---|---|
| `miso_party` | Git pin | `https://github.com/misofm/party-protocol.git` @ `9374c6eed64c907722ac1c93813c76dc7912b357` | production |
| `platform_link` | local-path | `../lib/platform_link` | production |
| `party_social` | local-path | `../party_social` | test-only |

`miso_party` is the manifest's only Git pin. `platform_link` and `party_social`
are local-path dependencies, not floating; `party_social` is excluded from
the production graph by `modes = ["test"]`. `Move.lock` retains both
environment pins, and `Published.toml` is retained unchanged.

## Verification

- Package tests: **9/9** on both Testnet and Mainnet, including five
  expected-failure paths for wrong-cap absent/present/equal set and clear.
- Strict Testnet and Mainnet lint builds passed with warnings as errors.
- Production instruction coverage: **100.00%** on both Testnet and Mainnet
  (`set_link`, `clear_link`, `has_link`, and `link`).
- Event tests cover exact primitive parent ID and payload fields, one-event
  deltas for insert/different replacement/present clear, silence for equal
  replacement, absent/repeated clear and views, distinct X/Instagram streams and parties,
  and the shared-party cap-holder/reader workflow.
- Repository aggregate (re-run 2026-10-21): **146/146** tests across the 11
  packages with zero warnings, strict Mainnet and Testnet builds; all 11
  production modules at **100.00%**.

## Published metadata

The retained `Published.toml` is the sole record of the prior immutable Testnet package id;
it is not repeated here.
Its dependency inputs predate the pending exact-pin reconciliation. Fresh
immutable publication uses the admin CLI with `--allow-republish`; only after
confirmed success may it replace the target network block.
