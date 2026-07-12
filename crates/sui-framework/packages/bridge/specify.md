# Specified Properties for Sui Bridge

## Property 1: Message Uniqueness (P-001)
- **Statement:** For all valid bridge transfer messages `M` approved by the validators, if `M` is claimed successfully (resulting in a token mint), then `M.claimed` is permanently set to `true`, and no subsequent transaction can claim `M` again.
- **Impact if false:** Critical. A double-execution vulnerability allows an attacker to replay a bridge message indefinitely, minting infinite tokens and stealing funds.
- **Counterexample Bound:** `<= 2` actors, `<= 2` claim transactions, same message `M`.
- **Rank:** 1

## Property 2: Conservation of Value Within Rate Limits (P-002)
- **Statement:** For all bridge claims, if `bypass_limiter` is false, the `amount` transferred must strictly pass `limiter.check_and_record_sending_transfer` and not exceed the current rolling window limit.
- **Impact if false:** High. An attacker could drain the bridge faster than the security bounds allow.
- **Rank:** 2
