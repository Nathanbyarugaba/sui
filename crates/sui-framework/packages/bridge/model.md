# Sui Bridge Verification Model

## State
- `paused`: Boolean indicating if the bridge is currently paused.
- `treasury`: Stores and mints supported token types (`Coin<T>`).
- `token_transfer_records`: A map storing bridge messages and their statuses. Keys are derived from `(source_chain, message_type, bridge_seq_num)`.
- `record`: The inner entry inside `token_transfer_records`, possessing:
    - `message`: `BridgeMessage` object.
    - `verified_signatures`: `Option<vector<vector<u8>>>`, non-empty if the bridge authority set has signed off on it.
    - `claimed`: Boolean.
- `limiter`: Limits the amount of tokens that can be bridged based on rolling volume calculations.
- `clock`: Global clock tracking system time.

## Transitions
### `claim_token_internal<T>`
- **Preconditions:**
  1. `inner.paused` is false.
  2. `token_transfer_records` contains a record matching the derived `key`.
  3. The `record` is a token message.
  4. The `record` has `verified_signatures` (is approved).
  5. If `record.claimed` is true, the transition aborts early returning `None`.
  6. `target_chain` matching `inner.chain_id`.
  7. `route` must be valid (`get_route`).
  8. Provided type `T` matches `token_type` from the message payload.
  9. Transfer amount is within `limiter` bounds OR `bypass_limiter` is true (more than 48 hours have passed since the event occurred according to `timestamp_ms`).
- **Writes:**
  1. Mint `token_payload.token_amount()` to a new `Coin<T>`.
  2. Set `record.claimed = true`.
- **Outputs:**
  1. `(Some(Coin<T>), owner)` which is then transferred to the user in `claim_and_transfer_token`.

## Assumptions
1. `verified_signatures` are soundly checked against an honest supermajority of bridge authorities. (EXPLICIT)
2. `message::create_key` yields unique records for every valid bridge transfer. (EXPLICIT)
3. Cryptographic time via `clock` is strictly increasing and monotonic. (INFERRED)
