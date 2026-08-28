(* lib/corplex.ml - Master Library Module for Corplex Kernel *)

module Types = Types
module Ast = Ast
module Context = Context
module Effects = Effects
module StaticAnalyzer = Static_analyzer
module RecurrenceSolver = Recurrence_solver
module Amortized = Amortized
module Spatiotemporal = Spatiotemporal_complexity
module DynamicProfiler = Dynamic_profiler
module MagicTrace = Magic_trace

let analyze_recurrence ~a ~b ~c ~k =
  RecurrenceSolver.solve_master_theorem ~a ~b ~c ~k

let analyze_akra_bazzi ~terms ~driving_degree =
  RecurrenceSolver.solve_akra_bazzi ~terms ~driving_degree

let simulate_amortized_dynamic_array n =
  let ops = Amortized.DynamicArray.simulate_n_pushes n in
  let phi_0 = Amortized.DynamicArray.potential Amortized.DynamicArray.initial_state in
  let phi_final = Amortized.DynamicArray.potential { size = n; capacity = (let rec p2 c = if c >= n then c else p2 (c * 2) in p2 1) } in
  let (holds, actual, amortized) = Amortized.verify_potential_invariant ops phi_0 phi_final in
  (ops, holds, actual, amortized)

let profile_dataset points =
  DynamicProfiler.fit_candidate_models points
