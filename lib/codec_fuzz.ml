(* lib/codec_fuzz.ml - Tokenizer & Codec Bijective Fuzzing Engine *)

type fuzz_result = {
  total_iterations : int;
  is_bijective : bool;
  counter_example : string option;
  decoded_counter_example : string option;
  failure_diagnostic : string option;
}

let generate_utf8_corpus () : string list =
  [
    "Hello World";
    "The quick brown fox jumps over the lazy dog";
    "   leading and trailing spaces   ";
    "\n\t\r newlines and tabs \n";
    "1234567890 + - * / = % $ # @ !";
    "Python, OCaml, C++, Rust, Zig, Agda, Rzk";
    "Привет мир! Тестирование токенизатора";
    "你好世界！这是一个神经网络分词测试";
    "مرحبا بالعالم! اختبار الترميز اللغوي";
    "🚀 Quantum Computing ⚡ Neural Tensor 🧠 Formal Verification";
    "UTF-8 Astral: 𝒳 𝒴 𝒵 𝄞 𝄢 𝄡";
    "Special tokens: <unk> <s> </s> <pad> <0x00> <0xFF>";
    "Accents: é, à, ü, ö, ä, î, ç, ñ, å, ø";
    "SentencePiece prefix:  test  tokenization";
    "Byte-BPE prefix: Ġtest Ġtokenization";
  ]

let fuzz_codec_roundtrip ~encode ~decode ?custom_corpus ~iterations () : fuzz_result =
  let corpus = match custom_corpus with
    | Some c -> c
    | None -> generate_utf8_corpus ()
  in
  let corpus_len = List.length corpus in
  let failure = ref None in
  let total_runs = ref 0 in

  for iter = 0 to iterations - 1 do
    if Option.is_none !failure then begin
      incr total_runs;
      let base_str = List.nth corpus (iter mod corpus_len) in
      let test_str =
        if iter < corpus_len then base_str
        else Printf.sprintf "%s [%d] %s" base_str iter (String.make (iter mod 5) ' ')
      in
      let tokens = encode test_str in
      let reconstructed = decode tokens in
      if reconstructed <> test_str then begin
        let diag = Printf.sprintf "Bijection broken: input length %d, output length %d" (String.length test_str) (String.length reconstructed) in
        failure := Some (test_str, reconstructed, diag)
      end
    end
  done;

  match !failure with
  | Some (inp, out, diag) -> {
      total_iterations = !total_runs;
      is_bijective = false;
      counter_example = Some inp;
      decoded_counter_example = Some out;
      failure_diagnostic = Some diag;
    }
  | None -> {
      total_iterations = !total_runs;
      is_bijective = true;
      counter_example = None;
      decoded_counter_example = None;
      failure_diagnostic = None;
    }

let verify_byte_bpe_inversion ~byte_to_unicode ~unicode_to_byte : bool * string =
  let broken = ref [] in
  for b = 0 to 255 do
    let u_str = byte_to_unicode b in
    let b_recovered = unicode_to_byte u_str in
    if b_recovered <> b then broken := b :: !broken
  done;
  if !broken = [] then (true, "Byte-BPE mapping is a strict bijection across all 256 bytes.")
  else (false, Printf.sprintf "Byte-BPE mapping failed for %d bytes (e.g. byte 0x%02X)" (List.length !broken) (List.hd !broken))
