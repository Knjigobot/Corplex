(* lib/tensor_invariants.ml - Neural Tensor & Numerical Invariant Verification *)

type quant_error_report = {
  max_absolute_error : float;
  mean_squared_error : float;
  max_relative_error : float;
  is_within_bound : bool;
}

type rope_mode =
  | Adjacent_Pairs
  | Split_Half

type rope_verification_report = {
  mode : rope_mode;
  is_orthogonal : bool;
  max_norm_drift : float;
  dot_product_shift_invariance : bool;
}

type distribution_report = {
  sum : float;
  is_normalized : bool;
  has_nans_or_infs : bool;
  min_val : float;
  max_val : float;
  entropy : float;
}

let verify_quant_error ~original ~dequantized ~max_allowed_err =
  let len = min (Array.length original) (Array.length dequantized) in
  if len = 0 then {
    max_absolute_error = 0.0;
    mean_squared_error = 0.0;
    max_relative_error = 0.0;
    is_within_bound = true;
  } else
    let max_abs = ref 0.0 in
    let sum_sq = ref 0.0 in
    let max_rel = ref 0.0 in
    for i = 0 to len - 1 do
      let orig = original.(i) in
      let deq = dequantized.(i) in
      let diff = abs_float (orig -. deq) in
      if diff > !max_abs then max_abs := diff;
      sum_sq := !sum_sq +. (diff *. diff);
      let rel = diff /. (abs_float orig +. 1e-7) in
      if rel > !max_rel then max_rel := rel
    done;
    let mse = !sum_sq /. float_of_int len in
    let is_within = !max_abs <= max_allowed_err in
    {
      max_absolute_error = !max_abs;
      mean_squared_error = mse;
      max_relative_error = !max_rel;
      is_within_bound = is_within;
    }

let norm_squared (arr : float array) : float =
  Array.fold_left (fun acc x -> acc +. (x *. x)) 0.0 arr

let dot_product (a : float array) (b : float array) : float =
  let len = min (Array.length a) (Array.length b) in
  let sum = ref 0.0 in
  for i = 0 to len - 1 do
    sum := !sum +. (a.(i) *. b.(i))
  done;
  !sum

let apply_rope ~(mode : rope_mode) ~(dim : int) ~(pos : int) ~(theta : float) (vec : float array) : float array =
  let out = Array.copy vec in
  let half = dim / 2 in
  match mode with
  | Adjacent_Pairs ->
      for i = 0 to half - 1 do
        let freq = 1.0 /. (theta ** (float_of_int (2 * i) /. float_of_int dim)) in
        let angle = float_of_int pos *. freq in
        let cos_a = cos angle in
        let sin_a = sin angle in
        let idx = i * 2 in
        if idx + 1 < dim && idx + 1 < Array.length vec then begin
          let x0 = vec.(idx) in
          let x1 = vec.(idx + 1) in
          out.(idx) <- (x0 *. cos_a) -. (x1 *. sin_a);
          out.(idx + 1) <- (x0 *. sin_a) +. (x1 *. cos_a)
        end
      done;
      out
  | Split_Half ->
      for i = 0 to half - 1 do
        let freq = 1.0 /. (theta ** (float_of_int (2 * i) /. float_of_int dim)) in
        let angle = float_of_int pos *. freq in
        let cos_a = cos angle in
        let sin_a = sin angle in
        if i + half < dim && i + half < Array.length vec then begin
          let x0 = vec.(i) in
          let x1 = vec.(i + half) in
          out.(i) <- (x0 *. cos_a) -. (x1 *. sin_a);
          out.(i + half) <- (x0 *. sin_a) +. (x1 *. cos_a)
        end
      done;
      out

let verify_rope_invariants ~mode ~dim ~pos ~theta ~q ~k ~tolerance =
  let orig_q_norm = norm_squared q in
  let orig_k_norm = norm_squared k in
  let q_rot = apply_rope ~mode ~dim ~pos ~theta q in
  let k_rot = apply_rope ~mode ~dim ~pos ~theta k in
  let rot_q_norm = norm_squared q_rot in
  let rot_k_norm = norm_squared k_rot in
  let norm_drift_q = abs_float (rot_q_norm -. orig_q_norm) in
  let norm_drift_k = abs_float (rot_k_norm -. orig_k_norm) in
  let max_drift = max norm_drift_q norm_drift_k in
  let is_ortho = max_drift <= tolerance in

  (* Verify shift invariance: <R_{m+s} q, R_{n+s} k> == <R_m q, R_n k> *)
  let dot_base = dot_product q_rot k_rot in
  let q_shift = apply_rope ~mode ~dim ~pos:(pos + 10) ~theta q in
  let k_shift = apply_rope ~mode ~dim ~pos:(pos + 10) ~theta k in
  let dot_shifted = dot_product q_shift k_shift in
  let shift_invariant = abs_float (dot_base -. dot_shifted) <= tolerance in

  {
    mode;
    is_orthogonal = is_ortho;
    max_norm_drift = max_drift;
    dot_product_shift_invariance = shift_invariant;
  }

let verify_softmax_distribution ~probs ~tolerance =
  let sum = ref 0.0 in
  let has_bad = ref false in
  let min_v = ref max_float in
  let max_v = ref (-. max_float) in
  let entropy = ref 0.0 in

  Array.iter (fun p ->
    if Float.is_nan p || Float.is_infinite p then has_bad := true
    else begin
      if p < !min_v then min_v := p;
      if p > !max_v then max_v := p;
      sum := !sum +. p;
      if p > 1e-12 then entropy := !entropy -. (p *. log p)
    end
  ) probs;

  let is_normalized = (not !has_bad) && abs_float (!sum -. 1.0) <= tolerance && (!min_v >= -. tolerance) in
  {
    sum = !sum;
    is_normalized;
    has_nans_or_infs = !has_bad;
    min_val = !min_v;
    max_val = !max_v;
    entropy = !entropy;
  }

let verify_rmsnorm_scaling ~output ~target_rms ~tolerance =
  let len = Array.length output in
  if len = 0 then (true, 0.0)
  else
    let sum_sq = Array.fold_left (fun acc x -> acc +. (x *. x)) 0.0 output in
    let rms = sqrt (sum_sq /. float_of_int len) in
    let diff = abs_float (rms -. target_rms) in
    (diff <= tolerance, rms)
