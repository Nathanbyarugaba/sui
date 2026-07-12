---
name: protocol-verify
description: Theorem-driven protocol verification: promise -> property -> counterexample -> repair -> prove -> refine -> regression
---

# Protocol Verify

Theorem-driven protocol verification.

**Instructions for Jules:**

When asked to formally verify a target or run the protocol-verify skill, you must execute the following pipeline manually. Do NOT write automated scripts with fake proofs. Instead, do the work using your own reasoning block, file reading tools, and Python scripts where deterministic analysis is required.

## Phase 1: Triage
Identify the highest-risk mechanisms based on potential loss of funds, consensus divergence, concurrency, and cross-layer assumptions. Check `crates/sui-bridge/src/`, `crates/sui-framework/packages/sui-system/sources/staking_pool.move`, and `crates/sui-framework/packages/sui-framework/sources/coin.move`. Select a specific mechanism to analyze.

## Phase 2: Model
Reconstruct the mechanism as a state-transition system. Define the actors, state, views, transitions, time, exceptions, and assumptions. Read the code directly (e.g., using `read_file` or `grep`) to build an accurate model. DO NOT hallucinate the model. Document it clearly.

## Phase 3: Specify
Convert the modeled mechanism into quantified, falsifiable property registry entries. The properties must be falsifiable and verifiable, such as "Message Uniqueness" for the bridge or "Total Supply Conservation" for the token framework.

## Phase 4: Falsify
Act as an adversary to find counterexamples for the properties. Write Python scripts if needed to analyze the boundary conditions or perform combinatorial testing on the states you extracted. Identify if the property holds under adversarial conditions.

## Phase 5: Adjudicate & Refine
Attempt to refute the counterexamples found in Phase 4. Map model-to-code divergences, and derive safe transition rules. Find where the code diverges from the strict model.

## Phase 6: Prove
Formalize the model in Rocq (`.v` files) inside `research/proofs/`. Attempt to prove the property or formally refute it. Use `run_in_bash_session` to invoke `coqc` locally on your generated `.v` files to earn the MACHINE_CHECKED_PROOF status. DO NOT produce dummy proofs like `l = l` or `n + m = m + n`. Prove something directly related to the model you extracted, even if it is a simplified abstraction. Keep it honest: if it doesn't compile without Admits, label it PROOF_SKETCH_ONLY.

## Phase 7: Evidence & Synthesize
Assemble regression tests and the final evidence chain report. Output this report to `research/report.md`.
