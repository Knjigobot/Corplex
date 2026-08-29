(* lib/cache_trace.mli - Magic-Trace Inner-Loop Cache & Memory Thrash Monitor *)

type cache_level =
  | L1_Data_32KB
  | L2_512KB
  | L3_Shared

type thrash_warning = {
  function_name : string;
  working_set_bytes : int;
  exceeded_level : cache_level;
  redundant_transforms_count : int;
  is_spill_detected : bool;
  recommendation : string;
}

type cache_monitor

val create_monitor : unit -> cache_monitor

val track_buffer_access :
  cache_monitor ->
  address:int ->
  size_bytes:int ->
  is_write:bool ->
  unit

val track_transformation :
  cache_monitor ->
  address:int ->
  transform_name:string ->
  unit

val evaluate_working_set :
  cache_monitor ->
  fn_name:string ->
  thrash_warning

val reset_monitor : cache_monitor -> unit
