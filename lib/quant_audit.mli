(* lib/quant_audit.mli - Bitwise Quantization Layout & Superblock Validator *)

type quant_format =
  | Q4_0
  | Q4_K
  | Q5_K
  | Q6_K
  | Q8_0

type audit_report = {
  format : quant_format;
  block_size : int;
  element_count : int;
  bit_exact_match : bool;
  max_ulp_difference : int;
  discrepancy_indices : int list;
  diagnostic_message : string;
}

val decode_f16 : int -> float

val encode_f16 : float -> int

val dequant_q4_0_reference :
  raw_bytes:string ->
  offset:int ->
  float array

val dequant_q4_k_reference :
  raw_bytes:string ->
  offset:int ->
  float array

val audit_dequantizer :
  format:quant_format ->
  raw_bytes:string ->
  offset:int ->
  candidate_dequant:(string -> int -> float array) ->
  audit_report

val audit_q4_k_scale_packing :
  scales_bytes:bytes ->
  is_valid_layout:bool * string
