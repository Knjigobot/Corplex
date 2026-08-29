(* lib/tensor_invariants.mli - Neural Tensor & Numerical Invariant Verification *)

type quant_error_report = {
  max_absolute_error : float;
  mean_squared_error : float;
  max_relative_error : float;
  is_within_bound : bool;
}

type rope_mode =
  | Adjacent_Pairs  (* LLaMA / Mistral style: [x0, x1], [x2, x3], ... *)
  | Split_Half      (* Qwen2 / Puro style: [x0, x_{d/2}], [x1, x_{d/2+1}], ... *)

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

val verify_quant_error :
  original:float array ->
  dequantized:float array ->
  max_allowed_err:float ->
  quant_error_report

val verify_rope_invariants :
  mode:rope_mode ->
  dim:int ->
  pos:int ->
  theta:float ->
  q:float array ->
  k:float array ->
  tolerance:float ->
  rope_verification_report

val verify_softmax_distribution :
  probs:float array ->
  tolerance:float ->
  distribution_report

val verify_rmsnorm_scaling :
  output:float array ->
  target_rms:float ->
  tolerance:float ->
  bool * float
