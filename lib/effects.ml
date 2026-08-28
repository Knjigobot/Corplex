(* lib/effects.ml - OxCaml Algebraic Effects for Cost Accounting & Step Profiling *)

open Effect
open Effect.Deep
open Types

type _ Effect.t +=
  | Tick_Step : int64 -> unit Effect.t
  | Track_Alloc : int64 -> unit Effect.t
  | Push_Stack_Frame : string -> unit Effect.t
  | Pop_Stack_Frame : unit -> unit Effect.t
  | Reversible_Checkpoint : unit -> (unit -> unit) Effect.t

type execution_profile = {
  total_steps : int64;
  total_alloc_bytes : int64;
  peak_stack_depth : int;
  call_trace : (string * int64) list;
}

let profile_execution (f : unit -> 'a) : 'a * execution_profile =
  let steps = ref 0L in
  let allocs = ref 0L in
  let stack = ref [] in
  let peak_depth = ref 0 in
  let trace = ref [] in
  let undo_trail = ref [] in

  let res =
    try_with f ()
      { effc = (fun (type c) (eff : c Effect.t) ->
          match eff with
          | Tick_Step n -> Some (fun (k : (c, _) continuation) ->
              let prev = !steps in
              steps := Int64.add !steps n;
              undo_trail := (fun () -> steps := prev) :: !undo_trail;
              continue k ())
          | Track_Alloc bytes -> Some (fun (k : (c, _) continuation) ->
              let prev = !allocs in
              allocs := Int64.add !allocs bytes;
              undo_trail := (fun () -> allocs := prev) :: !undo_trail;
              continue k ())
          | Push_Stack_Frame name -> Some (fun (k : (c, _) continuation) ->
              stack := name :: !stack;
              let depth = List.length !stack in
              if depth > !peak_depth then peak_depth := depth;
              trace := (name, !steps) :: !trace;
              continue k ())
          | Pop_Stack_Frame () -> Some (fun (k : (c, _) continuation) ->
              (match !stack with
               | _ :: rest -> stack := rest
               | [] -> ());
              continue k ())
          | Reversible_Checkpoint () -> Some (fun (k : (c, _) continuation) ->
              let snapshot_steps = !steps in
              let snapshot_allocs = !allocs in
              let rollback () =
                steps := snapshot_steps;
                allocs := snapshot_allocs
              in
              continue k rollback)
          | _ -> None) }
  in
  let profile = {
    total_steps = !steps;
    total_alloc_bytes = !allocs;
    peak_stack_depth = !peak_depth;
    call_trace = List.rev !trace;
  } in
  (res, profile)
