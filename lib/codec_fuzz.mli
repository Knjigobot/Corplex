(* lib/codec_fuzz.mli - Tokenizer & Codec Bijective Fuzzing Engine *)

type fuzz_result = {
  total_iterations : int;
  is_bijective : bool;
  counter_example : string option;
  decoded_counter_example : string option;
  failure_diagnostic : string option;
}

val generate_utf8_corpus : unit -> string list

val fuzz_codec_roundtrip :
  encode:(string -> 'token list) ->
  decode:('token list -> string) ->
  ?custom_corpus:string list ->
  iterations:int ->
  unit ->
  fuzz_result

val verify_byte_bpe_inversion :
  byte_to_unicode:(int -> string) ->
  unicode_to_byte:(string -> int) ->
  bool * string
