# Release Audit — `party_tags`

**Repository:** `https://github.com/misofm/party-protocol-extensions`
**Audit target:** `main`
**Reviewed:** 2026-09-11 with `sui 1.79.0-46f18562f1f5`
**Verification re-run:** 2026-10-21 with `sui 1.82.1`, after the house-style pass

## Verdict

Release-ready. No security or correctness findings remain.

## Implementation reviewed

`party_tags` is a state-attaching extension. It stores up to 30 exact-match
free-form strings through `typed_set`, with each tag constrained to 1–50 bytes.
All mutations require the matching `PartyAdminCap`; final removal reclaims the
field, clear is idempotent, and views are permissionless. Add/remove events
carry the party ID and the tag; populated clear events carry the party ID.
Normalization and rendering safety
remain client concerns.

## Exact manifest pins

| Dependency | Repository | Revision |
|---|---|---|
| `miso_party` | `https://github.com/misofm/party-protocol.git` | `7b25b1aa4f41ff16e82315b321736042d0debf57` |
| `typed_set` | `https://github.com/unconfirmedlabs/typed_set.git` | `b37474cbde166b7ddf8a3b615cd89f90182ace6f` |

The manifest has no local-path or floating dependencies.

## Verification

- Package tests: **23/23**, preserving the original 9 and adding event
  field, BCS-size, silence, identity, ordering, and
  authorization-order coverage.
- Production instruction coverage: **100.00%**.
- End-to-end scenario covers Party share, cap transfer, later tag write, and
  permissionless read from the shared Party.
- Strict Testnet and Mainnet builds passed with lint warnings as errors; package
  tests passed 23/23 on each network; production instruction coverage was
  100.00%.
- Repository aggregate (re-run 2026-10-21): **146/146** tests across the 11
  packages with zero warnings, strict Mainnet and Testnet builds; all 11
  production modules at **100.00%**.

## Published metadata

The retained `Published.toml` is the sole record of the prior immutable Testnet package id;
it is not repeated here.
It is prior-generation metadata wherever pending inputs differ. Fresh immutable
publication uses the admin CLI with `--allow-republish`; only after confirmed
success may it replace the target network block.
