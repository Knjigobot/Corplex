(* lib/dynamic_profiler.ml - Empirical Multi-Sample Regression & Profiler *)

open Types

type data_point = {
  n : float;
  time_ns : float;
  alloc_bytes : float;
}

let linear_regression (xs : float list) (ys : float list) : (float * float * float) =
  let n = float_of_int (List.length xs) in
  let sum_x = List.fold_left (+.) 0.0 xs in
  let sum_y = List.fold_left (+.) 0.0 ys in
  let sum_xx = List.fold_left (fun acc x -> acc +. (x *. x)) 0.0 xs in
  let sum_xy = List.fold_left2 (fun acc x y -> acc +. (x *. y)) 0.0 xs ys in
  let mean_y = sum_y /. n in
  let denom = (n *. sum_xx) -. (sum_x *. sum_x) in
  if abs_float denom < 1e-12 then (0.0, mean_y, 0.0)
  else
    let slope = ((n *. sum_xy) -. (sum_x *. sum_y)) /. denom in
    let intercept = (sum_y -. (slope *. sum_x)) /. n in
    let ss_tot = List.fold_left (fun acc y -> acc +. ((y -. mean_y) ** 2.0)) 0.0 ys in
    let ss_res = List.fold_left2 (fun acc x y ->
      let y_pred = (slope *. x) +. intercept in
      acc +. ((y -. y_pred) ** 2.0)
    ) 0.0 xs ys in
    let r2 = if ss_tot > 1e-12 then max 0.0 (1.0 -. (ss_res /. ss_tot)) else 1.0 in
    (slope, intercept, r2)

let fit_candidate_models (points : data_point list) : regression_result =
  let ns = List.map (fun p -> p.n) points in
  let times = List.map (fun p -> p.time_ns) points in
  let count = List.length points in

  let models = [
    (O_Const, List.map (fun _ -> 1.0) ns);
    (O_Log, List.map (fun n -> log (max 1.0 n)) ns);
    (O_Fractional 0.5, List.map (fun n -> sqrt n) ns);
    (O_Linear, ns);
    (O_QuasiLinear, List.map (fun n -> n *. log (max 1.0 n)) ns);
    (O_Quadratic, List.map (fun n -> n *. n) ns);
    (O_Cubic, List.map (fun n -> n *. n *. n) ns);
  ] in

  let evaluated = List.map (fun (asymp, x_trans) ->
    let (slope, intercept, r2) = linear_regression x_trans times in
    let mse =
      let sum_sq = List.fold_left2 (fun acc xt y ->
        let pred = (slope *. xt) +. intercept in
        acc +. ((y -. pred) ** 2.0)
      ) 0.0 x_trans times in
      sum_sq /. float_of_int count
    in
    let k_params = 2.0 in
    let aic = (float_of_int count *. log (max 1e-9 mse)) +. (2.0 *. k_params) in
    (asymp, r2, sqrt mse, aic, [("slope", slope); ("intercept", intercept)])
  ) models in

  (* Pick highest R^2 *)
  let best = List.fold_left (fun (b_asymp, b_r2, b_rmse, b_aic, b_params) (asymp, r2, rmse, aic, params) ->
    if r2 > b_r2 then (asymp, r2, rmse, aic, params)
    else (b_asymp, b_r2, b_rmse, b_aic, b_params)
  ) (O_Linear, -1.0, 0.0, 0.0, []) evaluated in

  let (best_asymp, best_r2, best_rmse, best_aic, best_params) = best in
  {
    best_fit_class = best_asymp;
    r_squared = best_r2;
    rmse = best_rmse;
    aic = best_aic;
    parameter_estimates = best_params;
  }
