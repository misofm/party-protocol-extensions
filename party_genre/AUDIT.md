# Release Audit — `party_genre`

**Repository:** `https://github.com/misofm/party-protocol-extensions`
**Audit target:** `main`
**Reviewed:** 2026-09-02 with `sui 1.78.1-722ac4fcf484`
**Verification re-run:** 2026-10-21 with `sui 1.82.1`, after the house-style pass

## Verdict

Release-ready. No security or correctness findings remain.

## Implementation reviewed

`party_genre` is a state-attaching extension. It stores up to 20 canonical
`Genre` object IDs through `typed_set`. Adding requires `&Genre`, proving the
vocabulary object exists; removal is by ID. All mutations require the matching
`PartyAdminCap`, final removal reclaims the field, and clear is idempotent.

## Exact manifest pins

| Dependency | Repository | Revision |
|---|---|---|
| `miso_party` | `https://github.com/misofm/party-protocol.git` | `65f22c8a0e8e32ac4ee52322536a15cbb5b0a429` |
| `typed_set` | `https://github.com/unconfirmedlabs/typed_set.git` | `b37474cbde166b7ddf8a3b615cd89f90182ace6f` |
| `genre` | `https://github.com/misofm/genre.git` | `0e9a031046ac3e199f23440377ad4ed3f6cd8dce` |

The manifest has no local-path or floating dependencies.

## Verification

- Package tests: **15/15**, including **13** expected-failure paths for
  duplicate, missing item, capacity, duplicate-before-capacity, and wrong-cap
  add/remove/clear authorization.
- Production instruction coverage: **100.00%**.
- End-to-end scenario covers the shared genre registry, immutable Genre,
  shared Party, transferred admin cap, cap-gated write, and later public read.
- Repository aggregate (re-run 2026-10-21): **146/146** tests across the 11
  packages with zero warnings, strict Mainnet and Testnet builds; all 11
  production modules at **100.00%**.

## Published metadata

The retained `Published.toml` is the sole record of the prior immutable Testnet package id;
it is not repeated here.
It is prior-generation metadata wherever pending inputs differ. Fresh immutable
publication uses the admin CLI with `--allow-republish`; only after confirmed
success may it replace the target network block.
