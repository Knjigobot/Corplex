(* bin/main.ml - Native CLI for Corplex Spatiotemporal Complexity Analysis Engine *)

open Corplex
open Corplex.Types

let print_banner () =
  Printf.printf "======================================================================\n";
  Printf.printf "  CORPLEX: Spatiotemporal Complexity Analysis Engine in OxCaml\n";
  Printf.printf "  Cordis Meta-Framework & Jane Street Modal System Runtime\n";
  Printf.printf "======================================================================\n\n"

let demo_master_theorem () =
  Printf.printf "--- [1] Master Theorem Solver Engine ---\n";
  let demo_cases = [
    ("MergeSort", 2.0, 2.0, 1.0, 0.0);
    ("Strassen Matrix Mult", 7.0, 2.0, 2.0, 0.0);
    ("Binary Search", 1.0, 2.0, 0.0, 0.0);
    ("Karatsuba Integer Mult", 3.0, 2.0, 1.0, 0.0);
  ] in
  List.iter (fun (name, a, b, c, k) ->
    Printf.printf "\nAnalyzing Algorithm: %s\n" name;
    let (res, steps) = RecurrenceSolver.solve_master_theorem ~a ~b ~c ~k in
    match res with
    | Case_1 { critical_exponent; derived_bound } ->
        Printf.printf "  Case: 1 (Leaf Dominated, p = %.4f)\n" critical_exponent;
        Printf.printf "  Bound: %s\n" derived_bound.latex_notation
    | Case_2 { critical_exponent; derived_bound; _ } ->
        Printf.printf "  Case: 2 (Balanced Work, p = %.4f)\n" critical_exponent;
        Printf.printf "  Bound: %s\n" derived_bound.latex_notation
    | Case_3 { critical_exponent; derived_bound; _ } ->
        Printf.printf "  Case: 3 (Root Dominated, p = %.4f)\n" critical_exponent;
        Printf.printf "  Bound: %s\n" derived_bound.latex_notation
    | Inapplicable err ->
        Printf.printf "  Inapplicable: %s\n" err
  ) demo_cases

let demo_amortized_analysis () =
  Printf.printf "\n--- [2] Physicist's Potential Method (Phi Invariant) ---\n";
  let n = 32 in
  let (ops, holds, sum_actual, sum_amortized) = Corplex.simulate_amortized_dynamic_array n in
  Printf.printf "Simulating Dynamic Array Doubling (%d operations):\n" n;
  Printf.printf "  Total Actual Work (Sum c_i):     %.1f\n" sum_actual;
  Printf.printf "  Total Amortized Work (Sum a_i):  %.1f\n" sum_amortized;
  Printf.printf "  Invariant Inequation Verified:   %s\n" (if holds then "PASS (Sum a_i >= Sum c_i)" else "FAIL");
  Printf.printf "  Amortized Cost Per Push:         O(1) Constant\n"

let demo_spatiotemporal_tradeoffs () =
  Printf.printf "\n--- [3] Cordis Spatiotemporal Pareto Analysis ---\n";
  let temporal = {
    kind = Big_Theta;
    asymptotic = O_QuasiLinear;
    latex_notation = "O(n log n)";
    human_description = "Divide-and-Conquer Sorting";
  } in
  let spatial = {
    kind = Big_O;
    asymptotic = O_Const;
    latex_notation = "O(1)";
    human_description = "Bounded RingBuffer Stream";
  } in
  let comm = {
    kind = Big_O;
    asymptotic = O_Const;
    latex_notation = "O(1)";
    human_description = "Local GADT Coeffect";
  } in
  let analysis = Spatiotemporal.analyze_cordis_pipeline ~temporal ~spatial ~comm in
  Printf.printf "Tradeoff Product: %s\n" analysis.tradeoff_product_latex;
  Printf.printf "Pareto Status:    %s\n" (if analysis.is_pareto_optimal then "PARETO-OPTIMAL" else "SUB-OPTIMAL");
  Printf.printf "Recommendation:   %s\n" analysis.recommendation

let () =
  print_banner ();
  demo_master_theorem ();
  demo_amortized_analysis ();
  demo_spatiotemporal_tradeoffs ();
  Printf.printf "\n======================================================================\n";
  Printf.printf "  Corplex Native OxCaml Execution Completed Successfully.\n";
  Printf.printf "======================================================================\n"
