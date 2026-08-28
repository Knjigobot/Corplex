(* test/test_corplex.ml - Comprehensive Test Suite for Corplex Kernel *)

open Corplex
open Corplex.Types
open Corplex.Ast

let test_master_case_1 () =
  (* Strassen Matrix Multiplication: T(n) = 7 T(n/2) + Theta(n^2) *)
  let (res, _) = RecurrenceSolver.solve_master_theorem ~a:7.0 ~b:2.0 ~c:2.0 ~k:0.0 in
  match res with
  | Case_1 { critical_exponent; _ } ->
      assert (abs_float (critical_exponent -. 2.80735) < 0.01);
      Printf.printf "[PASS] Master Theorem Case 1 (Strassen O(n^2.81))\n"
  | _ -> failwith "Failed Master Theorem Case 1"

let test_master_case_2 () =
  (* MergeSort: T(n) = 2 T(n/2) + Theta(n) *)
  let (res, _) = RecurrenceSolver.solve_master_theorem ~a:2.0 ~b:2.0 ~c:1.0 ~k:0.0 in
  match res with
  | Case_2 { critical_exponent; derived_bound; _ } ->
      assert (abs_float (critical_exponent -. 1.0) < 1e-5);
      assert (derived_bound.asymptotic = O_QuasiLinear);
      Printf.printf "[PASS] Master Theorem Case 2 (MergeSort O(n log n))\n"
  | _ -> failwith "Failed Master Theorem Case 2"

let test_master_case_3 () =
  (* T(n) = 2 T(n/2) + Theta(n^2) *)
  let (res, _) = RecurrenceSolver.solve_master_theorem ~a:2.0 ~b:2.0 ~c:2.0 ~k:0.0 in
  match res with
  | Case_3 { critical_exponent; derived_bound; _ } ->
      assert (abs_float (critical_exponent -. 1.0) < 1e-5);
      assert (derived_bound.asymptotic = O_Quadratic);
      Printf.printf "[PASS] Master Theorem Case 3 (Root-dominated O(n^2))\n"
  | _ -> failwith "Failed Master Theorem Case 3"

let test_akra_bazzi () =
  (* T(n) = T(n/3) + T(2n/3) + Theta(n) -> p = 1 -> O(n log n) *)
  let (bound, _) = RecurrenceSolver.solve_akra_bazzi ~terms:[(1.0, 1.0 /. 3.0); (1.0, 2.0 /. 3.0)] ~driving_degree:1.0 in
  assert (bound.asymptotic = O_QuasiLinear || bound.asymptotic = O_Linear);
  Printf.printf "[PASS] Akra-Bazzi Unequal Divide & Conquer\n"

let test_amortized_array () =
  let (ops, holds, actual, amortized) = Corplex.simulate_amortized_dynamic_array 64 in
  assert (holds);
  assert (amortized >= actual);
  Printf.printf "[PASS] Amortized Dynamic Array Invariant (Sum Amortized = %.1f >= Sum Actual = %.1f)\n" amortized actual

let test_static_analyzer () =
  let dummy_ast =
    For_Loop {
      var_name = "i";
      lower_bound = Const_Int 0;
      upper_bound = Var "n";
      step = Const_Int 1;
      body = For_Loop {
        var_name = "j";
        lower_bound = Const_Int 0;
        upper_bound = Var "n";
        step = Const_Int 1;
        body = Assign ("sum", BinOp (Add, Var "sum", Const_Int 1));
      };
    }
  in
  let depth = StaticAnalyzer.max_loop_depth dummy_ast in
  assert (depth = 2);
  let branches = StaticAnalyzer.count_branches dummy_ast in
  assert (branches = 2);
  Printf.printf "[PASS] Static AST Analyzer (Loop Depth = 2, Branches = 2)\n"

let test_magic_trace () =
  let buf = MagicTrace.create_buffer 100 in
  let compute_val = MagicTrace.with_span buf ~name:"fast_matrix_block" ~category:"math" (fun () ->
    let sum = ref 0 in
    for i = 1 to 1000 do sum := !sum + i done;
    !sum
  ) in
  assert (compute_val = 500500);
  let evts = MagicTrace.snapshot buf in
  assert (List.length evts = 2); (* 1 Begin, 1 End *)
  let json = MagicTrace.to_perfetto_json evts in
  assert (String.length json > 50);
  let trigger = MagicTrace.create_trigger buf (Latency_Threshold_Ns 1000L) in
  let triggered = MagicTrace.check_and_snapshot trigger ~duration_ns:50000L ~name:"test_spike" in
  assert (Option.is_some triggered);
  Printf.printf "[PASS] MagicTrace Nanosecond Span & Perfetto Exporter (Events Captured = %d)\n" (List.length evts)

let () =
  Printf.printf "=== Running Corplex OxCaml Unit Tests ===\n";
  test_master_case_1 ();
  test_master_case_2 ();
  test_master_case_3 ();
  test_akra_bazzi ();
  test_amortized_array ();
  test_static_analyzer ();
  test_magic_trace ();
  Printf.printf "=== All OxCaml Tests Successfully Passed! ===\n"
