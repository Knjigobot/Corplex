(* lib/context.ml - Cordis Dynamic Context & Coeffect Provider for Complexity Metrics *)

open Types

(* GADT representing complexity profiling keys and their associated dynamic types *)
type _ key =
  | StepCounter : int64 ref key
  | HeapAllocCounter : int64 ref key
  | ActiveRecurrence : recurrence_spec option ref key
  | CurrentCallDepth : int ref key
  | MaxObservedDepth : int ref key
  | RingBufferWatermark : int key
  | InferredComplexity : complexity_bound option ref key
  | AmortizedBankBalance : float ref key

module type CONTEXT = sig
  val get : 'a key -> 'a
  val has : 'a key -> bool
  val with_binding : 'a key -> 'a -> (unit -> 'b) -> 'b
end

module InMemoryContext : sig
  include CONTEXT
  val create : unit -> (module CONTEXT)
  val bind : 'a key -> 'a -> unit
  val unbind : 'a key -> unit
  val reset : unit -> unit
end = struct
  type entry = Entry : 'a key * 'a -> entry
  let registry : entry list ref = ref []

  let rec find_key : type a. a key -> entry list -> a option =
    fun target entries ->
      match entries with
      | [] -> None
      | Entry (k, v) :: rest ->
        match (target, k) with
        | StepCounter, StepCounter -> Some v
        | HeapAllocCounter, HeapAllocCounter -> Some v
        | ActiveRecurrence, ActiveRecurrence -> Some v
        | CurrentCallDepth, CurrentCallDepth -> Some v
        | MaxObservedDepth, MaxObservedDepth -> Some v
        | RingBufferWatermark, RingBufferWatermark -> Some v
        | InferredComplexity, InferredComplexity -> Some v
        | AmortizedBankBalance, AmortizedBankBalance -> Some v
        | _ -> find_key target rest

  let get : type a. a key -> a =
    fun k ->
      match find_key k !registry with
      | Some v -> v
      | None -> failwith "Complexity coeffect key not satisfied in context"

  let has : type a. a key -> bool =
    fun k ->
      match find_key k !registry with
      | Some _ -> true
      | None -> false

  let bind : type a. a key -> a -> unit =
    fun k v -> registry := Entry (k, v) :: !registry

  let rec remove_key : type a. a key -> entry list -> entry list =
    fun target entries ->
      match entries with
      | [] -> []
      | Entry (k, v) :: rest ->
        let matches =
          match (target, k) with
          | StepCounter, StepCounter -> true
          | HeapAllocCounter, HeapAllocCounter -> true
          | ActiveRecurrence, ActiveRecurrence -> true
          | CurrentCallDepth, CurrentCallDepth -> true
          | MaxObservedDepth, MaxObservedDepth -> true
          | RingBufferWatermark, RingBufferWatermark -> true
          | InferredComplexity, InferredComplexity -> true
          | AmortizedBankBalance, AmortizedBankBalance -> true
          | _ -> false
        in
        if matches then rest else Entry (k, v) :: remove_key target rest

  let unbind : type a. a key -> unit =
    fun k -> registry := remove_key k !registry

  let reset () = registry := []

  let with_binding : type a b. a key -> a -> (unit -> b) -> b =
    fun k v f ->
      let prev = !registry in
      registry := Entry (k, v) :: !registry;
      Fun.protect ~finally:(fun () -> registry := prev) f

  let create () = (module struct
    let get = get
    let has = has
    let with_binding = with_binding
  end : CONTEXT)
end
