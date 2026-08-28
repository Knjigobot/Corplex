(* lib/types.ml - Core Types & Asymptotic Bounds for Corplex Kernel *)

type asymptotic_class =
  | O_Const                   (* O(1) *)
  | O_DoubleLog               (* O(log log n) *)
  | O_Log                     (* O(log n) *)
  | O_PolyLog of float        (* O(log^k n) *)
  | O_Fractional of float     (* O(n^p) with 0 < p < 1, e.g. O(sqrt(n)) *)
  | O_Linear                  (* O(n) *)
  | O_QuasiLinear             (* O(n log n) *)
  | O_Quadratic               (* O(n^2) *)
  | O_Cubic                   (* O(n^3) *)
  | O_Polynomial of float     (* O(n^k) *)
  | O_Exponential of float    (* O(c^n) *)
  | O_Factorial               (* O(n!) *)
  | O_Unknown of string

type bound_kind =
  | Big_O
  | Big_Omega
  | Big_Theta
  | Soft_O                    (* O-tilde ignoring polylogarithmic factors *)

type complexity_bound = {
  kind : bound_kind;
  asymptotic : asymptotic_class;
  latex_notation : string;
  human_description : string;
}

type cost_vector = {
  time_steps : int64;
  auxiliary_space_bytes : int64;
  resident_memory_bytes : int64;
  heap_allocations : int64;
  communication_messages : int64;
}

type recurrence_spec =
  | Master_Form of {
      a : float;       (* Number of subproblems (a >= 1) *)
      b : float;       (* Subproblem division factor (b > 1) *)
      c : float;       (* Degree of driving function f(n) = Theta(n^c * log^k n) *)
      k : float;       (* Logarithmic exponent *)
    }
  | Akra_Bazzi of {
      terms : (float * float) list; (* (a_i, b_i) pairs where a_i > 0, 0 < b_i < 1 *)
      driving_degree : float;        (* g(n) = Theta(n^p) *)
    }
  | Linear_Recurrence of {
      coefficients : float list;    (* c_1, c_2, ..., c_k for T(n) = sum c_i T(n-i) *)
      base_cases : float list;
    }

type master_theorem_case =
  | Case_1 of { critical_exponent : float; derived_bound : complexity_bound }
  | Case_2 of { critical_exponent : float; k_val : float; derived_bound : complexity_bound }
  | Case_3 of { critical_exponent : float; regularity_holds : bool; derived_bound : complexity_bound }
  | Inapplicable of string

type potential_function = {
  name : string;
  formula : string;
  initial_potential : float;
  compute_potential : float -> float; (* State -> Potential float *)
}

type amortized_operation = {
  op_name : string;
  actual_cost : float;
  potential_delta : float;
  amortized_cost : float;
}

type regression_result = {
  best_fit_class : asymptotic_class;
  r_squared : float;
  rmse : float;
  aic : float;
  parameter_estimates : (string * float) list;
}

type static_metrics = {
  cyclomatic_complexity : int;
  halstead_volume : float;
  max_loop_nesting_depth : int;
  branch_count : int;
  recursion_depth_upper_bound : asymptotic_class;
  spatial_coeffect_bound : asymptotic_class;
}

type full_analysis_report = {
  algorithm_name : string;
  time_complexity : complexity_bound;
  space_complexity : complexity_bound;
  amortized_bound : complexity_bound option;
  spatiotemporal_tradeoff : string;
  static_metrics : static_metrics;
  empirical_regression : regression_result option;
  derivation_steps : string list;
}
