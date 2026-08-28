(* lib/spatiotemporal_complexity.ml - Cordis Space-Time & Communication Complexity *)

open Types

type tradeoff_class =
  | Optimal_Linear_Zero_Alloc   (* T(n) = O(n), S(n) = O(1) *)
  | Log_Space_Search            (* T(n) = O(log n), S(n) = O(1) *)
  | Divide_Conquer_Optimal      (* T(n) = O(n log n), S(n) = O(log n) stack *)
  | Memoized_Dynamic_Prog       (* T(n) = O(n^2), S(n) = O(n^2) table *)
  | Unbounded_Spatial_Leak      (* S(n) = O(n) when O(1) ring buffer was possible *)

type spatiotemporal_analysis = {
  spatial_bound : complexity_bound;
  temporal_bound : complexity_bound;
  communication_bound : complexity_bound;
  tradeoff_product_latex : string;
  is_pareto_optimal : bool;
  recommendation : string;
}

let analyze_cordis_pipeline ~temporal ~spatial ~comm : spatiotemporal_analysis =
  let is_optimal =
    match (temporal.asymptotic, spatial.asymptotic) with
    | (O_Const, O_Const)
    | (O_Log, O_Const)
    | (O_Linear, O_Const)
    | (O_QuasiLinear, O_Log)
    | (O_QuasiLinear, O_Const) -> true
    | _ -> false
  in
  let recommendation =
    if is_optimal then
      "Optimal Spatiotemporal Configuration: Zero-GC modal allocations & bounded streaming context."
    else
      match spatial.asymptotic with
      | O_Linear | O_Quadratic ->
          "Consider refactoring with Cordis RingBuffer or Jane Street modal local_ references to reduce spatial footprint to O(1)."
      | _ -> "Temporal latency can potentially be optimized with divide-and-conquer parallelism."
  in
  let prod_latex = Printf.sprintf "T(n) \\times S(n) = %s \\times %s" temporal.latex_notation spatial.latex_notation in
  {
    spatial_bound = spatial;
    temporal_bound = temporal;
    communication_bound = comm;
    tradeoff_product_latex = prod_latex;
    is_pareto_optimal = is_optimal;
    recommendation;
  }
