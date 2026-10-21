# Release Audit — `party_cta`

**Repository:** `https://github.com/misofm/party-protocol-extensions`
**Audit target:** `main`
**Reviewed:** 2026-09-11 with `sui 1.79.0-46f18562f1f5`
**Verification re-run:** 2026-10-21 with `sui 1.82.1`, after the house-style pass

## Verdict

Release-ready. No security or correctness findings remain.

## Implementation reviewed

`party_cta` is a state-attaching extension. It stores one ordered,
replace-whole `vector<Cta>` dynamic field on a Party. Labels are 1–60 bytes,
URLs are 1–2000 bytes, and the list is capped at 20. `set_ctas` and
`clear_ctas` require the matching `PartyAdminCap`; views are permissionless.
Changed set events carry the party ID and the complete ordered CTA list; clear
events carry the party ID; equal sets and absent clears are silent. The module
contains no funds or automation entrypoints.

## Exact manifest pins

| Dependency | Repository | Revision |
|---|---|---|
| `miso_party` | `https://github.com/misofm/party-protocol.git` | `65f22c8a0e8e32ac4ee52322536a15cbb5b0a429` |

The manifest has no local-path or floating dependencies.

## Verification

- Verified Testnet package tests: **18/18**, including expected-failure paths covering all four
  CTA validators, list capacity ordering, equal-write silence, component
  changes, and wrong-cap set/replace/clear authorization.
- Strict Testnet and Mainnet lint builds passed with warnings as errors.
- Production instruction coverage: **100.00%**.
- End-to-end scenario: Party creation and share, cap transfer, later cap-gated
  write to the shared Party, and permissionless read in another transaction.
- Repository aggregate (re-run 2026-10-21): **146/146** tests across the 11
  packages with zero warnings, strict Mainnet and Testnet builds; all 11
  production modules at **100.00%**.

## Published metadata

The retained `Published.toml` is the sole record of the prior immutable Testnet package id;
it is not repeated here.
It predates pending source wherever inputs differ. Fresh immutable publication
uses the admin CLI with `--allow-republish`; only a confirmed successful
transaction may replace the target network block.
