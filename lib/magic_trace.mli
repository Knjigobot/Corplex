(* lib/magic_trace.mli - Jane Street Magic-Trace Inspired Nanosecond Tracing & Outlier Snapshotting *)

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

type trace_buffer

val create_buffer : int -> trace_buffer

val record_event :
  trace_buffer ->
  name:string ->
  category:string ->
  phase:event_phase ->
  ?args:(string * string) list ->
  unit ->
  unit

val with_span :
  trace_buffer ->
  name:string ->
  category:string ->
  ?args:(string * string) list ->
  (unit -> 'a) ->
  'a

val snapshot : trace_buffer -> trace_event list

val to_perfetto_json : trace_event list -> string

val write_perfetto_trace : trace_buffer -> string -> unit

type trigger_policy =
  | Latency_Threshold_Ns of int64
  | Allocation_Spike of int64
  | Complexity_Anomaly of Types.asymptotic_class * int64

type snapshot_trigger

val create_trigger : trace_buffer -> trigger_policy -> snapshot_trigger

val check_and_snapshot : snapshot_trigger -> duration_ns:int64 -> name:string -> (string * trace_event list) option
