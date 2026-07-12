Require Import Bool.
Require Import PeanoNat.

(* Abstract state for Bridge Transfer Record *)
Inductive TransferRecord : Type :=
  | Unclaimed : TransferRecord
  | Claimed : TransferRecord.

(* Abstract Bridge state *)
Record BridgeState := {
  record : TransferRecord;
  minted : nat
}.

(* Transition function for claim_token_internal *)
Definition claim_token (s : BridgeState) (amount : nat) : BridgeState :=
  match s.(record) with
  | Unclaimed => {| record := Claimed; minted := s.(minted) + amount |}
  | Claimed => s (* early exit, no mint *)
  end.

(* Theorem: If a message is already claimed, attempting to claim it again mints 0 additional tokens. *)
Theorem double_claim_prevents_mint : forall (s : BridgeState) (amount : nat),
  s.(record) = Claimed ->
  (claim_token s amount).(minted) = s.(minted).
Proof.
  intros s amount H.
  unfold claim_token.
  rewrite H.
  reflexivity.
Qed.

(* Theorem: Once claimed, the record stays claimed. *)
Theorem claimed_is_monotonic : forall (s : BridgeState) (amount : nat),
  (claim_token s amount).(record) = Claimed ->
  (claim_token (claim_token s amount) amount).(record) = Claimed.
Proof.
  intros s amount H.
  unfold claim_token.
  destruct s.(record).
  - simpl. reflexivity.
  - simpl. exact H.
Qed.
