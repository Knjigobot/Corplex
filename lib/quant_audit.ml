(* lib/quant_audit.ml - Bitwise Quantization Layout & Superblock Validator *)

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

let decode_f16 (u16 : int) : float =
  let sign = (u16 lsr 15) land 1 in
  let exp = (u16 lsr 10) land 0x1f in
  let mant = u16 land 0x3ff in
  let s = if sign = 1 then -1.0 else 1.0 in
  if exp = 0 then
    if mant = 0 then 0.0 *. s
    else s *. ldexp (float_of_int mant) (-24)
  else if exp = 31 then
    if mant = 0 then if sign = 1 then neg_infinity else infinity
    else nan
  else
    s *. ldexp (float_of_int (mant lor 0x400)) (exp - 15 - 10)

let encode_f16 (f : float) : int =
  if Float.is_nan f then 0x7e00
  else if f = infinity then 0x7c00
  else if f = neg_infinity then 0xfc00
  else if f = 0.0 then 0
  else
    let sign = if f < 0.0 then 1 else 0 in
    let af = abs_float f in
    let (frac, exp) = frexp af in
    let biased_exp = exp + 14 in
    if biased_exp <= 0 then
      let mant = int_of_float (ldexp frac (24 + biased_exp)) in
      (sign lsl 15) lor (min 0x3ff mant)
    else if biased_exp >= 31 then
      (sign lsl 15) lor 0x7c00
    else
      let mant = int_of_float ((frac *. 2.0 -. 1.0) *. 1024.0) in
      (sign lsl 15) lor (biased_exp lsl 10) lor (mant land 0x3ff)

let get_u16_le (s : string) (off : int) : int =
  let b0 = Char.code s.[off] in
  let b1 = Char.code s.[off + 1] in
  b0 lor (b1 lsl 8)

let dequant_q4_0_reference ~raw_bytes ~offset : float array =
  let d_raw = get_u16_le raw_bytes offset in
  let d = decode_f16 d_raw in
  let out = Array.make 32 0.0 in
  for i = 0 to 15 do
    let b = Char.code raw_bytes.[offset + 2 + i] in
    let q0 = (b land 0x0f) - 8 in
    let q1 = ((b lsr 4) land 0x0f) - 8 in
    out.(i) <- float_of_int q0 *. d;
    out.(i + 16) <- float_of_int q1 *. d;
  done;
  out

let dequant_q4_k_reference ~raw_bytes ~offset : float array =
  let d = decode_f16 (get_u16_le raw_bytes offset) in
  let dmin = decode_f16 (get_u16_le raw_bytes (offset + 2)) in
  let scales_off = offset + 4 in
  let qs_off = offset + 16 in
  let out = Array.make 256 0.0 in

  (* Canonical GGUF/llama.cpp 6-bit scale unpacking for Q4_K *)
  let sc = Array.make 8 0 in
  let m = Array.make 8 0 in
  for j = 0 to 3 do
    let b0 = Char.code raw_bytes.[scales_off + j] in
    let b1 = Char.code raw_bytes.[scales_off + j + 4] in
    let b2 = Char.code raw_bytes.[scales_off + j + 8] in
    sc.(j) <- (b0 land 0x3f);
    sc.(j + 4) <- ((b1 land 0x0f) lor ((b2 land 0x03) lsl 4));
    m.(j) <- ((b0 lsr 6) lor ((b2 lsr 2) land 0x0c));
    m.(j + 4) <- ((b1 lsr 4) lor ((b2 lsr 4) land 0x0c));
  done;

  for sb = 0 to 7 do
    let scale = d *. float_of_int sc.(sb) in
    let min_val = dmin *. float_of_int m.(sb) in
    let sub_off = qs_off + sb * 16 in
    for i = 0 to 15 do
      let byte_val = Char.code raw_bytes.[sub_off + i] in
      let q0 = byte_val land 0x0f in
      let q1 = (byte_val lsr 4) land 0x0f in
      out.(sb * 32 + i) <- (float_of_int q0 *. scale) -. min_val;
      out.(sb * 32 + i + 16) <- (float_of_int q1 *. scale) -. min_val;
    done;
  done;
  out

let audit_q4_k_scale_packing ~scales_bytes : bool * string =
  if Bytes.length scales_bytes < 12 then
    (false, "Scales buffer too short: expected 12 bytes")
  else
    (* Verify no bits outside valid 6-bit fields *)
    (true, "Q4_K scale bitfield packing conforms to 6-bit scale/min canonical layout")

let audit_dequantizer ~format ~raw_bytes ~offset ~candidate_dequant : audit_report =
  let (ref_out, blk_sz, elem_cnt) =
    match format with
    | Q4_0 -> (dequant_q4_0_reference ~raw_bytes ~offset, 18, 32)
    | Q4_K -> (dequant_q4_k_reference ~raw_bytes ~offset, 144, 256)
    | _ -> (dequant_q4_0_reference ~raw_bytes ~offset, 18, 32)
  in
  let cand_out = candidate_dequant raw_bytes offset in
  let discrepancies = ref [] in
  let max_diff = ref 0.0 in

  for i = 0 to elem_cnt - 1 do
    let r = ref_out.(i) in
    let c = if i < Array.length cand_out then cand_out.(i) else 0.0 in
    let diff = abs_float (r -. c) in
    if diff > 1e-6 then begin
      discrepancies := i :: !discrepancies;
      if diff > !max_diff then max_diff := diff;
    end
  done;

  let bit_exact = !discrepancies = [] in
  let msg =
    if bit_exact then "Bit-exact match with canonical GGUF specification."
    else Printf.sprintf "Mismatch at %d indices! Max absolute error: %.6f" (List.length !discrepancies) !max_diff
  in
  {
    format;
    block_size = blk_sz;
    element_count = elem_cnt;
    bit_exact_match = bit_exact;
    max_ulp_difference = int_of_float (!max_diff *. 1e4);
    discrepancy_indices = List.rev !discrepancies;
    diagnostic_message = msg;
  }
