# Sui Protocol Verification Report: Bridge Mechanism

## 1. Executive Summary
| Property ID | Mechanism | Status | Impact | Confirmed CEs | Rocq Status |
|---|---|---|---|---|---|
| P-001 (Message Uniqueness) | Sui Native Bridge (`claim_token_internal`) | NO_COUNTEREXAMPLE_WITHIN_BOUND | Critical | 0 | MACHINE_CHECKED_PROOF |
| P-002 (Value Conservation / Limits) | Sui Native Bridge (`claim_token_internal`) | UNDER_SPECIFIED | High | 0 | PROOF_SKETCH_ONLY |

## 2. Findings & Evidence Chain
### P-001 (Message Uniqueness)
- **Property:** No bridge message can be claimed and minted more than once.
- **Counterexample Search:** A simulated combinatorial search bounds `<= 2` transactions interleaving the claim execution. It confirmed that `record.claimed = true` operates correctly as a linearity guard, returning early and safely for double-spend attempts.
- **Code Path:** `crates/sui-framework/packages/bridge/sources/bridge.move:466` and `604`.
- **Rocq Proof:** `research/proofs/P_001.v` - `double_claim_prevents_mint` cleanly proves `Qed` over the abstract transition relation.
- **Regression Invariant:** Existing VM-level capability and linear type semantics enforce this. No custom deterministic interleaving is required because the object is borrowed exclusively (`&mut Bridge`) inside the single PTB execution.

## 3. Design-Level and Implementation-Level Divergences
- **Implementation-level safe divergence:** The model abstracts away PTB (Programmable Transaction Block) scheduling. Sui PTBs process shared object writes serially. The model assumes we have to worry about inter-step concurrency within the function. The VM itself provides the guarantee, so no explicit locking logic in Move is necessary to prevent race conditions on the `claimed` boolean.

## 4. Permissiveness Opportunities
- **Delay bypass valve:** The `bypass_limiter` feature (`clock.timestamp_ms() > timestamp + 48 * 3600000`) is an explicit bypass for rate limits. While mathematically "unsafe" against strict rate limits, it is intentionally permissive to prevent total bridge freezes and ensure eventual liveness (via social/authority consensus resolving the limit ceiling within 48h).

## 5. Proof Status
- **P-001:** `MACHINE_CHECKED_PROOF`
  - Rocq file: `research/proofs/P_001.v`
  - Theorem: `double_claim_prevents_mint`
  - *Model Fidelity Caveats:* The Rocq model treats the token minting and boolean state as a simple atomic functional transition `BridgeState -> BridgeState`. It ignores gas, Move VM object aliasing, and Sui epochs, assuming the VM properly serializes requests as a pure function application.

## 6. Bound Search Details
- **P-001 NO_COUNTEREXAMPLE_WITHIN_BOUND:**
  - Explored 2-step sequences of `Unclaimed` -> `Claimed` with varying `bypass_limiter` bools.
  - State remained secure against double mints.
