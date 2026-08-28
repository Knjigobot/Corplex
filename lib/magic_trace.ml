(* lib/magic_trace.ml - Jane Street Magic-Trace Inspired Nanosecond Tracing & Outlier Snapshotting *)

open Types

type timestamp_ns = int64

type event_phase =
  | Begin
  | End
  | Instant
  | Counter of int64

type trace_event = {
  name : string;
  category : string;
  phase : event_phase;
  timestamp_ns : timestamp_ns;
  process_id : int;
  thread_id : int;
  args : (string * string) list;
}

type trace_buffer = {
  capacity : int;
  events : trace_event option array;
  mutable head : int;
  mutable count : int;
}

let get_current_ns () : int64 =
  let t = Sys.time () *. 1e9 in
  Int64.of_float t

let create_buffer capacity = {
  capacity;
  events = Array.make capacity None;
  head = 0;
  count = 0;
}

let record_event buf ~name ~category ~phase ?(args = []) () =
  let ts = get_current_ns () in
  let evt = {
    name;
    category;
    phase;
    timestamp_ns = ts;
    process_id = 1;
    thread_id = 1;
    args;
  } in
  buf.events.(buf.head) <- Some evt;
  buf.head <- (buf.head + 1) mod buf.capacity;
  if buf.count < buf.capacity then buf.count <- buf.count + 1

let with_span buf ~name ~category ?(args = []) f =
  record_event buf ~name ~category ~phase:Begin ~args ();
  let start_ns = get_current_ns () in
  let res =
    try f ()
    with e ->
      record_event buf ~name ~category ~phase:End ~args:(("exception", Printexc.to_string e) :: args) ();
      raise e
  in
  let duration_ns = Int64.sub (get_current_ns ()) start_ns in
  let final_args = ("duration_ns", Int64.to_string duration_ns) :: args in
  record_event buf ~name ~category ~phase:End ~args:final_args ();
  res

let snapshot buf =
  let result = ref [] in
  for i = 0 to buf.count - 1 do
    let idx = (buf.head - buf.count + i + buf.capacity) mod buf.capacity in
    match buf.events.(idx) with
    | Some evt -> result := evt :: !result
    | None -> ()
  done;
  List.rev !result

let escape_json_str s =
  let buf = Buffer.create (String.length s) in
  String.iter (function
    | '"' -> Buffer.add_string buf "\\\""
    | '\\' -> Buffer.add_string buf "\\\\"
    | '\n' -> Buffer.add_string buf "\\n"
    | '\r' -> Buffer.add_string buf "\\r"
    | '\t' -> Buffer.add_string buf "\\t"
    | c -> Buffer.add_char buf c
  ) s;
  Buffer.contents buf

let format_event_perfetto evt =
  let ph = match evt.phase with
    | Begin -> "\"B\""
    | End -> "\"E\""
    | Instant -> "\"i\""
    | Counter _ -> "\"C\""
  in
  let args_json =
    match evt.args with
    | [] -> "{}"
    | lst ->
        "{" ^ String.concat "," (List.map (fun (k, v) ->
          Printf.sprintf "\"%s\":\"%s\"" (escape_json_str k) (escape_json_str v)
        ) lst) ^ "}"
  in
  Printf.sprintf
    "{\"name\":\"%s\",\"cat\":\"%s\",\"ph\":%s,\"ts\":%Ld,\"pid\":%d,\"tid\":%d,\"args\":%s}"
    (escape_json_str evt.name)
    (escape_json_str evt.category)
    ph
    (Int64.div evt.timestamp_ns 1000L) (* Microseconds for Chrome/Perfetto *)
    evt.process_id
    evt.thread_id
    args_json

let to_perfetto_json (events : trace_event list) : string =
  let event_strs = List.map format_event_perfetto events in
  "{\n  \"traceEvents\": [\n    " ^
  String.concat ",\n    " event_strs ^
  "\n  ],\n  \"displayTimeUnit\": \"ns\"\n}\n"

let write_perfetto_trace buf filename =
  let evts = snapshot buf in
  let json = to_perfetto_json evts in
  let oc = open_out filename in
  output_string oc json;
  close_out oc

type trigger_policy =
  | Latency_Threshold_Ns of int64
  | Allocation_Spike of int64
  | Complexity_Anomaly of Types.asymptotic_class * int64

type snapshot_trigger = {
  buffer : trace_buffer;
  policy : trigger_policy;
  mutable triggers_fired : int;
}

let create_trigger buffer policy = {
  buffer;
  policy;
  triggers_fired = 0;
}

let check_and_snapshot trigger ~duration_ns ~name =
  let should_fire =
    match trigger.policy with
    | Latency_Threshold_Ns threshold -> duration_ns > threshold
    | Allocation_Spike _ -> false
    | Complexity_Anomaly (O_Const, max_ns) -> duration_ns > max_ns
    | Complexity_Anomaly (_, threshold) -> duration_ns > threshold
  in
  if should_fire then begin
    trigger.triggers_fired <- trigger.triggers_fired + 1;
    let filename = Printf.sprintf "magic_trace_%s_spike_%d.json" name trigger.triggers_fired in
    let evts = snapshot trigger.buffer in
    Some (filename, evts)
  end else
    None
