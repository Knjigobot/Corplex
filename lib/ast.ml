(* lib/ast.ml - AST Representations for Complexity Analysis *)

type binop = Add | Sub | Mul | Div | Mod | Eq | Neq | Lt | Le | Gt | Ge | And | Or

type unop = Neg | Not

type expr =
  | Var of string
  | Const_Int of int
  | Const_Float of float
  | Const_Bool of bool
  | BinOp of binop * expr * expr
  | UnOp of unop * expr
  | Array_Access of string * expr
  | Tuple of expr list
  | Call of string * expr list
  | Alloc_Array of expr * expr (* size, init_val *)
  | Perform_Effect of string * expr

type stmt =
  | Skip
  | Seq of stmt * stmt
  | Assign of string * expr
  | Array_Assign of string * expr * expr
  | If_Then_Else of expr * stmt * stmt
  | While_Loop of {
      condition : expr;
      body : stmt;
      inferred_bound : expr option;
    }
  | For_Loop of {
      var_name : string;
      lower_bound : expr;
      upper_bound : expr;
      step : expr;
      body : stmt;
    }
  | Divide_And_Conquer of {
      problem_size_var : string;
      subproblem_count : int;
      division_factor : float;
      combine_work : stmt;
      subproblems : stmt list;
    }
  | Return of expr option
  | Effect_Handler of {
      effect_name : string;
      handler_body : stmt;
      protected_body : stmt;
    }

type func_def = {
  fn_name : string;
  params : string list;
  body : stmt;
  is_recursive : bool;
  declared_space_mode : string option; (* e.g., "local_", "unique" *)
}

type program = {
  modules : string list;
  functions : func_def list;
}

let rec string_of_expr = function
  | Var v -> v
  | Const_Int i -> string_of_int i
  | Const_Float f -> string_of_float f
  | Const_Bool b -> string_of_bool b
  | BinOp (op, e1, e2) ->
      let op_str = match op with
        | Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/" | Mod -> "%"
        | Eq -> "==" | Neq -> "!=" | Lt -> "<" | Le -> "<=" | Gt -> ">" | Ge -> ">="
        | And -> "&&" | Or -> "||"
      in
      "(" ^ string_of_expr e1 ^ " " ^ op_str ^ " " ^ string_of_expr e2 ^ ")"
  | UnOp (op, e) ->
      let op_str = match op with Neg -> "-" | Not -> "!" in
      op_str ^ "(" ^ string_of_expr e ^ ")"
  | Array_Access (arr, idx) -> arr ^ "[" ^ string_of_expr idx ^ "]"
  | Tuple es -> "(" ^ String.concat ", " (List.map string_of_expr es) ^ ")"
  | Call (fn, args) -> fn ^ "(" ^ String.concat ", " (List.map string_of_expr args) ^ ")"
  | Alloc_Array (sz, _) -> "make_array(" ^ string_of_expr sz ^ ")"
  | Perform_Effect (eff, arg) -> "perform " ^ eff ^ "(" ^ string_of_expr arg ^ ")"
