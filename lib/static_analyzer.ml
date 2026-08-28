(* lib/static_analyzer.ml - AST Analysis, CFG & Halstead Complexity *)

open Ast
open Types

type cfg_node = {
  id : int;
  label : string;
  is_branch : bool;
}

type cfg = {
  nodes : cfg_node list;
  edges : (int * int) list;
}

let rec max_loop_depth = function
  | Skip | Assign _ | Array_Assign _ | Return _ -> 0
  | Seq (s1, s2) -> max (max_loop_depth s1) (max_loop_depth s2)
  | If_Then_Else (_, s1, s2) -> max (max_loop_depth s1) (max_loop_depth s2)
  | While_Loop { body; _ } -> 1 + max_loop_depth body
  | For_Loop { body; _ } -> 1 + max_loop_depth body
  | Divide_And_Conquer { combine_work; subproblems; _ } ->
      let sub_depth = List.fold_left (fun acc s -> max acc (max_loop_depth s)) 0 subproblems in
      max (max_loop_depth combine_work) sub_depth
  | Effect_Handler { handler_body; protected_body; _ } ->
      max (max_loop_depth handler_body) (max_loop_depth protected_body)

let rec count_branches = function
  | Skip | Assign _ | Array_Assign _ | Return _ -> 0
  | Seq (s1, s2) -> count_branches s1 + count_branches s2
  | If_Then_Else (_, s1, s2) -> 1 + count_branches s1 + count_branches s2
  | While_Loop { body; _ } -> 1 + count_branches body
  | For_Loop { body; _ } -> 1 + count_branches body
  | Divide_And_Conquer { combine_work; subproblems; _ } ->
      let sub = List.fold_left (fun acc s -> acc + count_branches s) 0 subproblems in
      1 + count_branches combine_work + sub
  | Effect_Handler { handler_body; protected_body; _ } ->
      1 + count_branches handler_body + count_branches protected_body

(* Cyclomatic complexity M = Predicates + 1 *)
let cyclomatic_complexity stmt =
  1 + count_branches stmt

let rec collect_halstead_symbols stmt (ops, operands) =
  match stmt with
  | Skip -> (ops, operands)
  | Assign (v, e) ->
      let ops' = ":=" :: ops in
      let operands' = v :: operands in
      collect_expr_symbols e (ops', operands')
  | Array_Assign (arr, idx, e) ->
      let ops' = "[]:=" :: ops in
      let operands' = arr :: operands in
      let s1 = collect_expr_symbols idx (ops', operands') in
      collect_expr_symbols e s1
  | Seq (s1, s2) ->
      let s' = collect_halstead_symbols s1 (";" :: ops, operands) in
      collect_halstead_symbols s2 s'
  | If_Then_Else (c, s1, s2) ->
      let s' = collect_expr_symbols c ("if" :: ops, operands) in
      let s'' = collect_halstead_symbols s1 s' in
      collect_halstead_symbols s2 s''
  | While_Loop { condition; body; _ } ->
      let s' = collect_expr_symbols condition ("while" :: ops, operands) in
      collect_halstead_symbols body s'
  | For_Loop { var_name; lower_bound; upper_bound; step; body } ->
      let ops' = "for" :: ops in
      let operands' = var_name :: operands in
      let s1 = collect_expr_symbols lower_bound (ops', operands') in
      let s2 = collect_expr_symbols upper_bound s1 in
      let s3 = collect_expr_symbols step s2 in
      collect_halstead_symbols body s3
  | Divide_And_Conquer { problem_size_var; combine_work; subproblems; _ } ->
      let operands' = problem_size_var :: operands in
      let s1 = collect_halstead_symbols combine_work ("dnc_combine" :: ops, operands') in
      List.fold_left (fun acc s -> collect_halstead_symbols s acc) s1 subproblems
  | Return (Some e) -> collect_expr_symbols e ("return" :: ops, operands)
  | Return None -> ("return" :: ops, operands)
  | Effect_Handler { effect_name; handler_body; protected_body } ->
      let operands' = effect_name :: operands in
      let s1 = collect_halstead_symbols handler_body ("handle" :: ops, operands') in
      collect_halstead_symbols protected_body s1

and collect_expr_symbols expr (ops, operands) =
  match expr with
  | Var v -> (ops, v :: operands)
  | Const_Int i -> (ops, string_of_int i :: operands)
  | Const_Float f -> (ops, string_of_float f :: operands)
  | Const_Bool b -> (ops, string_of_bool b :: operands)
  | BinOp (_, e1, e2) ->
      let s' = ("binop" :: ops, operands) in
      let s1 = collect_expr_symbols e1 s' in
      collect_expr_symbols e2 s1
  | UnOp (_, e) ->
      collect_expr_symbols e ("unop" :: ops, operands)
  | Array_Access (arr, idx) ->
      let operands' = arr :: operands in
      collect_expr_symbols idx ("[]" :: ops, operands')
  | Tuple es ->
      List.fold_left (fun acc e -> collect_expr_symbols e acc) ("tuple" :: ops, operands) es
  | Call (fn, args) ->
      let operands' = fn :: operands in
      List.fold_left (fun acc e -> collect_expr_symbols e acc) ("call" :: ops, operands') args
  | Alloc_Array (sz, init) ->
      let s1 = collect_expr_symbols sz ("alloc_array" :: ops, operands) in
      collect_expr_symbols init s1
  | Perform_Effect (eff, arg) ->
      let operands' = eff :: operands in
      collect_expr_symbols arg ("perform" :: ops, operands')

let unique_count lst =
  let module S = Set.Make(String) in
  let set = List.fold_left (fun acc item -> S.add item acc) S.empty lst in
  S.cardinal set

let compute_halstead_volume stmt =
  let (ops, operands) = collect_halstead_symbols stmt ([], []) in
  let n1 = float_of_int (List.length ops) in
  let n2 = float_of_int (List.length operands) in
  let eta1 = float_of_int (unique_count ops) in
  let eta2 = float_of_int (unique_count operands) in
  let n_total = n1 +. n2 in
  let vocab = eta1 +. eta2 in
  if vocab <= 1.0 then 0.0
  else n_total *. (log vocab /. log 2.0)

let analyze_function_static (fn : func_def) : static_metrics =
  let m = cyclomatic_complexity fn.body in
  let depth = max_loop_depth fn.body in
  let branches = count_branches fn.body in
  let volume = compute_halstead_volume fn.body in
  let inferred_depth =
    if fn.is_recursive then
      if depth > 0 then O_QuasiLinear else O_Log
    else
      O_Const
  in
  let space_bound =
    match fn.declared_space_mode with
    | Some "local_" | Some "unique" -> O_Const
    | _ -> if fn.is_recursive then O_Log else O_Const
  in
  {
    cyclomatic_complexity = m;
    halstead_volume = volume;
    max_loop_nesting_depth = depth;
    branch_count = branches;
    recursion_depth_upper_bound = inferred_depth;
    spatial_coeffect_bound = space_bound;
  }
