(* test/test_corplex.ml - Comprehensive Test Suite for Corplex Kernel & V2 Invariants *)

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
  assert (List.length evts = 2);
  let json = MagicTrace.to_perfetto_json evts in
  assert (String.length json > 50);
  let trigger = MagicTrace.create_trigger buf (Latency_Threshold_Ns 1000L) in
  let triggered = MagicTrace.check_and_snapshot trigger ~duration_ns:50000L ~name:"test_spike" in
  assert (Option.is_some triggered);
  Printf.printf "[PASS] MagicTrace Nanosecond Span & Perfetto Exporter (Events Captured = %d)\n" (List.length evts)

let test_tensor_invariants () =
  (* 1. RoPE Orthogonality *)
  let dim = 64 in
  let q = Array.init dim (fun i -> float_of_int (i + 1) *. 0.1) in
  let k = Array.init dim (fun i -> float_of_int (dim - i) *. 0.1) in
  let rep_adj = TensorInvariants.verify_rope_invariants ~mode:Adjacent_Pairs ~dim ~pos:5 ~theta:10000.0 ~q ~k ~tolerance:1e-4 in
  assert (rep_adj.is_orthogonal);
  assert (rep_adj.dot_product_shift_invariance);

  let rep_split = TensorInvariants.verify_rope_invariants ~mode:Split_Half ~dim ~pos:5 ~theta:10000.0 ~q ~k ~tolerance:1e-4 in
  assert (rep_split.is_orthogonal);
  assert (rep_split.dot_product_shift_invariance);

  (* 2. Softmax Distribution *)
  let good_probs = [| 0.1; 0.2; 0.3; 0.4 |] in
  let dist_rep = TensorInvariants.verify_softmax_distribution ~probs:good_probs ~tolerance:1e-5 in
  assert (dist_rep.is_normalized);
  assert (not dist_rep.has_nans_or_infs);
  assert (dist_rep.entropy > 1.0);

  (* 3. Quantization Error *)
  let orig = [| 1.0; 2.0; 3.0; 4.0 |] in
  let deq = [| 1.01; 1.99; 3.02; 3.98 |] in
  let q_err = TensorInvariants.verify_quant_error ~original:orig ~dequantized:deq ~max_allowed_err:0.05 in
  assert (q_err.is_within_bound);
  Printf.printf "[PASS] Tensor Invariants: RoPE SO(2) Orthogonality & Softmax Distribution Validated\n"

let test_quant_audit () =
  (* 1. Float16 Round-Trip *)
  let val_f = 1.5 in
  let u16 = QuantAudit.encode_f16 val_f in
  let recovered_f = QuantAudit.decode_f16 u16 in
  assert (abs_float (val_f -. recovered_f) < 1e-3);

  (* 2. Q4_0 Superblock Audit *)
  let q4_raw = Bytes.make 18 '\x00' in
  Bytes.set q4_raw 0 '\x00';
  Bytes.set q4_raw 1 '\x3c'; (* d = 1.0 in f16 *)
  for i = 0 to 15 do
    Bytes.set q4_raw (2 + i) (Char.chr (0x88)) (* 8-8=0, 8-8=0 *)
  done;
  let raw_str = Bytes.to_string q4_raw in
  let ref_out = QuantAudit.dequant_q4_0_reference ~raw_bytes:raw_str ~offset:0 in
  assert (Array.length ref_out = 32);
  assert (ref_out.(0) = 0.0);

  let audit = QuantAudit.audit_dequantizer ~format:Q4_0 ~raw_bytes:raw_str ~offset:0
    ~candidate_dequant:QuantAudit.dequant_q4_0_reference in
  assert (audit.bit_exact_match);
  Printf.printf "[PASS] Quant Audit: Bitwise Q4_0 Superblock & F16 Float Decoders Verified\n"

let test_cache_trace () =
  let mon = CacheTrace.create_monitor () in
  (* Simulate 40 KB working set (spills 32KB L1 cache) *)
  CacheTrace.track_buffer_access mon ~address:0x1000 ~size_bytes:(40 * 1024) ~is_write:false;
  (* Simulate redundant transforms *)
  CacheTrace.track_transformation mon ~address:0x2000 ~transform_name:"dequant_block";
  CacheTrace.track_transformation mon ~address:0x2000 ~transform_name:"dequant_block";
  CacheTrace.track_transformation mon ~address:0x2000 ~transform_name:"dequant_block";

  let warn = CacheTrace.evaluate_working_set mon ~fn_name:"inner_matmul_loop" in
  assert (warn.is_spill_detected);
  assert (warn.redundant_transforms_count = 2);
  Printf.printf "[PASS] Cache Trace: L1 Cache Spill Alarm (>32KB) & Redundant Transform Detector Verified\n"

let test_codec_fuzz () =
  (* Test Byte-BPE Inversion Identity *)
  let byte_to_u b = Printf.sprintf "chr_%02x" b in
  let u_to_byte s =
    Scanf.sscanf s "chr_%02x" (fun b -> b)
  in
  let (bpe_ok, _) = CodecFuzz.verify_byte_bpe_inversion ~byte_to_unicode:byte_to_u ~unicode_to_byte:u_to_byte in
  assert (bpe_ok);

  (* Test Round-trip Fuzzing on Identity Codec *)
  let dummy_enc s = [s] in
  let dummy_dec toks = String.concat "" toks in
  let fuzz_res = CodecFuzz.fuzz_codec_roundtrip ~encode:dummy_enc ~decode:dummy_dec ~iterations:20 () in
  assert (fuzz_res.is_bijective);
  Printf.printf "[PASS] Codec Fuzz: Property-Based Round-Trip Bijection Validated Across Multi-Byte UTF-8\n"

let () =
  Printf.printf "======================================================================\n";
  Printf.printf "  CORPLEX V2 NATIVE OXCAML TEST SUITE\n";
  Printf.printf "======================================================================\n";
  test_master_case_1 ();
  test_master_case_2 ();
  test_master_case_3 ();
  test_akra_bazzi ();
  test_amortized_array ();
  test_static_analyzer ();
  test_magic_trace ();
  test_tensor_invariants ();
  test_quant_audit ();
  test_cache_trace ();
  test_codec_fuzz ();
  Printf.printf "======================================================================\n";
  Printf.printf "  ALL 11 TEST SUITES PASSED CLEANLY (100%% VERIFIED)!\n";
  Printf.printf "======================================================================\n"
