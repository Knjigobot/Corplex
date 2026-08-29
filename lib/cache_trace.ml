(* lib/cache_trace.ml - Magic-Trace Inner-Loop Cache & Memory Thrash Monitor *)

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

type cache_monitor = {
  mutable total_bytes : int;
  accessed_addrs : (int, int) Hashtbl.t; (* addr -> access_count *)
  transformed_addrs : (int, int) Hashtbl.t; (* addr -> transform_count *)
}

let create_monitor () = {
  total_bytes = 0;
  accessed_addrs = Hashtbl.create 64;
  transformed_addrs = Hashtbl.create 64;
}

let track_buffer_access mon ~address ~size_bytes ~is_write:_ =
  if not (Hashtbl.mem mon.accessed_addrs address) then begin
    Hashtbl.add mon.accessed_addrs address 1;
    mon.total_bytes <- mon.total_bytes + size_bytes
  end else
    let count = Hashtbl.find mon.accessed_addrs address in
    Hashtbl.replace mon.accessed_addrs address (count + 1)

let track_transformation mon ~address ~transform_name:_ =
  let count = if Hashtbl.mem mon.transformed_addrs address then Hashtbl.find mon.transformed_addrs address else 0 in
  Hashtbl.replace mon.transformed_addrs address (count + 1)

let evaluate_working_set mon ~fn_name =
  let l1_threshold = 32 * 1024 in (* 32 KB *)
  let l2_threshold = 512 * 1024 in (* 512 KB *)

  let redundant_count = ref 0 in
  Hashtbl.iter (fun _ count ->
    if count > 1 then redundant_count := !redundant_count + (count - 1)
  ) mon.transformed_addrs;

  let (level, is_spill, rec_msg) =
    if mon.total_bytes > l2_threshold then
      (L3_Shared, true, "Critical: Working set exceeds L2 cache (512KB). Massive RAM memory bus traffic.")
    else if mon.total_bytes > l1_threshold then
      (L2_512KB, true, "Warning: Working set exceeds L1 data cache (32KB). Consider chunking into L1 cache blocks.")
    else
      (L1_Data_32KB, false, "Optimal: Working set resides fully inside L1 CPU cache.")
  in

  let full_rec =
    if !redundant_count > 0 then
      Printf.sprintf "%s Also detected %d redundant transformations of identical memory addresses; cache or hoist transformations out of inner loops." rec_msg !redundant_count
    else rec_msg
  in

  {
    function_name = fn_name;
    working_set_bytes = mon.total_bytes;
    exceeded_level = level;
    redundant_transforms_count = !redundant_count;
    is_spill_detected = is_spill;
    recommendation = full_rec;
  }

let reset_monitor mon =
  mon.total_bytes <- 0;
  Hashtbl.clear mon.accessed_addrs;
  Hashtbl.clear mon.transformed_addrs
