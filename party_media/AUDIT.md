# Release Audit — `party_media`

**Repository:** `https://github.com/misofm/party-protocol-extensions`
**Audit target:** pending working-tree source on `codex/rich-events`
**Date:** 2026-09-11
**Toolchain:** `sui 1.79.0-46f18562f1f5`

## Verdict

Release-ready. No security or correctness findings remain.

## Implementation reviewed

`party_media` is a state-attaching extension. It stores one nonzero Walrus
quilt ID (`u256`) as a Party dynamic field. Set/replace and clear require the
matching `PartyAdminCap`; reads are permissionless. Set events are emitted for
inserts and changed replacements and carry the party ID and new quilt id
(64-byte payload); clear events carry the party ID (32 bytes). Equal
replacements are silent. Patch roles are an off-chain
convention, and no media bytes or funds are stored.

## Exact manifest pins

| Dependency | Repository | Revision |
|---|---|---|
| `miso_party` | `https://github.com/misofm/party-protocol.git` | `defb05a6066cdf7e8949f9162f00589d38eef6ce` |

The manifest has no local-path or floating dependencies.

## Verification

- Package tests: **11/11**, including **7** expected-failure paths covering zero
  validation precedence, equal-write silence, wrong-cap set on
  absent/present/equal state, and wrong-cap clear on absent/present state.
- Strict Testnet and Mainnet lint builds passed with warnings as errors.
- Production instruction coverage: **100.00%** on both Testnet and Mainnet.
- End-to-end scenario covers Party share, cap transfer, later cap-gated media
  write, and permissionless read from the shared Party, with views confirmed
  event-silent.
## Published metadata

The retained `Published.toml` is the sole record of the prior immutable Testnet package id;
it is not repeated here.
It is prior-generation metadata wherever pending inputs differ. Fresh immutable
publication uses the admin CLI with `--allow-republish`; only after confirmed
success may it replace the target network block.
