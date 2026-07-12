# Refinement & Permissiveness

## Safe Path Divergences (Code vs Model)
- **Model Assumes:** State mutations happen in an atomic environment where no interleaved transactions can sneak in between checking `claimed` and setting `claimed = true`.
- **Code Enforcement:** Sui Move uses object capabilities and strict linear types (like hot potato patterns). Interleaved execution is not an issue since PTBs (Programmable Transaction Blocks) execute sequentially on a given shared object (`Bridge`). Concurrency bugs are averted by the Move VM.

## Permissiveness Opportunities
- The limit bypass rule (`clock.timestamp_ms() > timestamp + 48 * 3600000`) acts as a safety valve. If the bridge authorities sign a large transaction that hits limits, users wait 48 hours to claim. This is an explicit design choice, but it creates a delay for legitimate large users. It is technically more permissive than a strict limit, enabling liveness.
