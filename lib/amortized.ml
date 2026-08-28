(* lib/amortized.ml - Physicist's Potential Method & Banker's Accounting Engine *)

open Types

module DynamicArray = struct
  type state = {
    size : int;
    capacity : int;
  }

  let initial_state = { size = 0; capacity = 1 }

  (* Potential function: Phi(D) = 2*size - capacity *)
  let potential state =
    float_of_int (max 0 (2 * state.size - state.capacity))

  let push state =
    let phi_prev = potential state in
    if state.size < state.capacity then
      let new_state = { state with size = state.size + 1 } in
      let actual_cost = 1.0 in
      let phi_curr = potential new_state in
      let delta_phi = phi_curr -. phi_prev in
      let amortized_cost = actual_cost +. delta_phi in
      (new_state, {
        op_name = "Push (No Resize)";
        actual_cost;
        potential_delta = delta_phi;
        amortized_cost;
      })
    else
      let new_cap = state.capacity * 2 in
      let new_state = { size = state.size + 1; capacity = new_cap } in
      let actual_cost = float_of_int (state.size + 1) in (* copying old elements + 1 new *)
      let phi_curr = potential new_state in
      let delta_phi = phi_curr -. phi_prev in
      let amortized_cost = actual_cost +. delta_phi in
      (new_state, {
        op_name = Printf.sprintf "Push (Resize %d -> %d)" state.capacity new_cap;
        actual_cost;
        potential_delta = delta_phi;
        amortized_cost;
      })

  let simulate_n_pushes n =
    let rec loop i st acc =
      if i >= n then List.rev acc
      else
        let (st', op) = push st in
        loop (i + 1) st' (op :: acc)
    in
    loop 0 initial_state []
end

module CordisRingBuffer = struct
  type state = {
    head : int;
    tail : int;
    capacity : int;
    count : int;
  }

  let create capacity = { head = 0; tail = 0; capacity; count = 0 }

  let potential _ = 0.0 (* Zero-potential strictly bounded memory *)

  let push_sample state =
    let new_count = min (state.count + 1) state.capacity in
    let new_head = (state.head + 1) mod state.capacity in
    let new_tail = if state.count = state.capacity then (state.tail + 1) mod state.capacity else state.tail in
    let new_state = { state with head = new_head; tail = new_tail; count = new_count } in
    (new_state, {
      op_name = "RingBuffer Push";
      actual_cost = 1.0;
      potential_delta = 0.0;
      amortized_cost = 1.0;
    })
end

module BankersAccounting = struct
  type account = {
    mutable balance : float;
    mutable total_deposited : float;
    mutable total_consumed : float;
  }

  let create () = { balance = 0.0; total_deposited = 0.0; total_consumed = 0.0 }

  let charge account ~actual_cost ~amortized_charge =
    let delta = amortized_charge -. actual_cost in
    account.balance <- account.balance +. delta;
    if delta > 0.0 then account.total_deposited <- account.total_deposited +. delta
    else account.total_consumed <- account.total_consumed +. (-. delta);
    account.balance >= 0.0 (* Invariant: credit balance must never be negative *)
end

let verify_potential_invariant (ops : amortized_operation list) (phi_0 : float) (phi_final : float) : bool * float * float =
  let sum_actual = List.fold_left (fun acc op -> acc +. op.actual_cost) 0.0 ops in
  let sum_amortized = List.fold_left (fun acc op -> acc +. op.amortized_cost) 0.0 ops in
  let holds = sum_amortized >= sum_actual && (phi_final >= phi_0) in
  (holds, sum_actual, sum_amortized)
