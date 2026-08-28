(* lib/recurrence_solver.ml - Master Theorem, Akra-Bazzi & Recurrence Equations *)

open Types

let eps = 1e-7

let log_base base x = log x /. log base

let format_asymptotic_class = function
  | O_Const -> "O(1)"
  | O_DoubleLog -> "O(\\log \\log n)"
  | O_Log -> "O(\\log n)"
  | O_PolyLog k -> Printf.sprintf "O(\\log^{%.1f} n)" k
  | O_Fractional p -> Printf.sprintf "O(n^{%.2f})" p
  | O_Linear -> "O(n)"
  | O_QuasiLinear -> "O(n \\log n)"
  | O_Quadratic -> "O(n^2)"
  | O_Cubic -> "O(n^3)"
  | O_Polynomial k -> Printf.sprintf "O(n^{%.2f})" k
  | O_Exponential b -> Printf.sprintf "O(%.2f^n)" b
  | O_Factorial -> "O(n!)"
  | O_Unknown s -> s

let classify_power (p : float) (log_k : float) : asymptotic_class * string =
  if abs_float p < eps then
    if abs_float log_k < eps then (O_Const, "O(1)")
    else if abs_float (log_k -. 1.0) < eps then (O_Log, "O(\\log n)")
    else (O_PolyLog log_k, Printf.sprintf "O(\\log^{%.1f} n)" log_k)
  else if abs_float (p -. 0.5) < eps then
    (O_Fractional 0.5, "O(\\sqrt{n})")
  else if abs_float (p -. 1.0) < eps then
    if abs_float log_k < eps then (O_Linear, "O(n)")
    else if abs_float (log_k -. 1.0) < eps then (O_QuasiLinear, "O(n \\log n)")
    else (O_Polynomial p, Printf.sprintf "O(n \\log^{%.1f} n)" log_k)
  else if abs_float (p -. 2.0) < eps && abs_float log_k < eps then
    (O_Quadratic, "O(n^2)")
  else if abs_float (p -. 3.0) < eps && abs_float log_k < eps then
    (O_Cubic, "O(n^3)")
  else
    (O_Polynomial p, Printf.sprintf "O(n^{%.2f})" p)

let solve_master_theorem ~a ~b ~c ~k : master_theorem_case * string list =
  if a < 1.0 || b <= 1.0 then
    (Inapplicable "Master Theorem requires a >= 1 and b > 1", ["Invalid parameters: a < 1 or b <= 1"])
  else
    let p = log_base b a in
    let diff = c -. p in
    let mut_steps = ref [] in
    let add_step s = mut_steps := s :: !mut_steps in

    add_step (Printf.sprintf "Identified Recurrence: T(n) = %.2f T(n/%.2f) + \\Theta(n^{%.2f} \\log^{%.1f} n)" a b c k);
    add_step (Printf.sprintf "Computed critical exponent: p = \\log_b(a) = \\log_{%.2f}(%.2f) = %.4f" b a p);
    add_step (Printf.sprintf "Compared driving polynomial degree c = %.4f with critical exponent p = %.4f (difference c - p = %.4f)" c p diff);

    if diff < -.eps then begin
      (* Case 1: c < log_b a *)
      let (asymp, notation) = classify_power p 0.0 in
      let bound = {
        kind = Big_Theta;
        asymptotic = asymp;
        latex_notation = "\\Theta(n^{\\log_b a}) = " ^ notation;
        human_description = Printf.sprintf "Case 1 dominates at leaves: Theta(n^%.4f)" p;
      } in
      add_step "Case 1 applies: c < \\log_b(a). The work at recursive leaves dominates.";
      add_step (Printf.sprintf "Conclusion: T(n) = \\Theta(n^{%.4f})" p);
      (Case_1 { critical_exponent = p; derived_bound = bound }, List.rev !mut_steps)
    end else if abs_float diff <= eps then begin
      (* Case 2: c = log_b a *)
      let new_k = k +. 1.0 in
      let (asymp, notation) = classify_power p new_k in
      let bound = {
        kind = Big_Theta;
        asymptotic = asymp;
        latex_notation = "\\Theta(n^{\\log_b a} \\log^{k+1} n) = " ^ notation;
        human_description = Printf.sprintf "Case 2 evenly balanced work across tree levels: Theta(n^%.4f log^%.1f n)" p new_k;
      } in
      add_step "Case 2 applies: c = \\log_b(a). Work is evenly distributed across tree levels.";
      add_step (Printf.sprintf "Conclusion: T(n) = \\Theta(n^{%.4f} \\log^{%.1f} n)" p new_k);
      (Case_2 { critical_exponent = p; k_val = k; derived_bound = bound }, List.rev !mut_steps)
    end else begin
      (* Case 3: c > log_b a *)
      let (asymp, notation) = classify_power c k in
      let bound = {
        kind = Big_Theta;
        asymptotic = asymp;
        latex_notation = "\\Theta(n^c \\log^k n) = " ^ notation;
        human_description = Printf.sprintf "Case 3 dominates at root: Theta(n^%.4f log^%.1f n)" c k;
      } in
      add_step "Case 3 applies: c > \\log_b(a). The divide/combine work at root dominates.";
      add_step (Printf.sprintf "Regularity condition checked: a*(n/b)^c <= d*n^c for d = %.4f < 1" (a /. (b ** c)));
      add_step (Printf.sprintf "Conclusion: T(n) = \\Theta(n^{%.4f} \\log^{%.1f} n)" c k);
      (Case_3 { critical_exponent = p; regularity_holds = true; derived_bound = bound }, List.rev !mut_steps)
    end

let solve_akra_bazzi ~(terms : (float * float) list) ~(driving_degree : float) : complexity_bound * string list =
  (* Solve sum a_i * b_i^p = 1 *)
  let f_p p =
    List.fold_left (fun acc (a_i, b_i) -> acc +. a_i *. (b_i ** p)) 0.0 terms
  in
  let rec bsearch low high iter =
    if iter > 100 then (low +. high) /. 2.0
    else
      let mid = (low +. high) /. 2.0 in
      let v = f_p mid in
      if abs_float (v -. 1.0) < 1e-9 then mid
      else if v > 1.0 then bsearch mid high (iter + 1)
      else bsearch low mid (iter + 1)
  in
  let p = bsearch (-10.0) 20.0 0 in
  let steps = [
    Printf.sprintf "Akra-Bazzi characteristic equation: \\sum a_i b_i^p = 1 with %d subproblem terms" (List.length terms);
    Printf.sprintf "Numerically solved characteristic exponent: p = %.4f" p;
    Printf.sprintf "Driving function degree: g(n) = \\Theta(n^{%.2f})" driving_degree;
  ] in
  let (asymp, notation) =
    if driving_degree < p then
      classify_power p 0.0
    else if abs_float (driving_degree -. p) < eps then
      classify_power p 1.0
    else
      classify_power driving_degree 0.0
  in
  let bound = {
    kind = Big_Theta;
    asymptotic = asymp;
    latex_notation = "\\Theta(n^p) = " ^ notation;
    human_description = Printf.sprintf "Akra-Bazzi general bound: Theta(n^%.4f)" (max p driving_degree);
  } in
  (bound, steps)

let solve_linear_fibonacci () : complexity_bound * string list =
  let phi = (1.0 +. sqrt 5.0) /. 2.0 in
  let bound = {
    kind = Big_Theta;
    asymptotic = O_Exponential phi;
    latex_notation = "\\Theta(\\phi^n) \\approx \\Theta(1.618^n)";
    human_description = "Golden Ratio exponential expansion from linear recurrence T(n) = T(n-1) + T(n-2) + O(1)";
  } in
  let steps = [
    "Characteristic Equation: r^2 - r - 1 = 0";
    Printf.sprintf "Roots: r_1 = (1 + sqrt(5))/2 = %.6f (Golden Ratio phi), r_2 = (1 - sqrt(5))/2 = %.6f" phi ((1.0 -. sqrt 5.0) /. 2.0);
    "Dominant root r_1 gives Theta(phi^n)";
  ] in
  (bound, steps)
