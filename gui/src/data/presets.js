/**
 * Corplex Algorithm Presets with OxCaml Code, Recurrence Specs & Benchmark Drivers
 */

export const ALGORITHM_PRESETS = {
  mergesort: {
    id: 'mergesort',
    name: 'MergeSort (Divide & Conquer)',
    category: 'Sorting / Divide & Conquer',
    recurrence: { a: 2, b: 2, c: 1, k: 0 },
    theoreticalTime: 'O(n log n)',
    theoreticalSpace: 'O(n)',
    description: 'Classic divide-and-conquer algorithm splitting array into 2 halves with linear merge cost.',
    oxcamlCode: `(* MergeSort in OxCaml *)
let rec merge (l1 : int list) (l2 : int list) : int list =
  match (l1, l2) with
  | ([], l) | (l, []) -> l
  | (x :: xs, y :: ys) ->
      if x <= y then x :: merge xs l2
      else y :: merge l1 ys

let rec mergesort (arr : int list) : int list =
  match arr with
  | [] | [_] -> arr
  | _ ->
      let (left, right) = split arr in
      merge (mergesort left) (mergesort right)`,
    benchmarkDriver: (n) => {
      const arr = Array.from({ length: n }, () => Math.random());
      function ms(a) {
        if (a.length <= 1) return a;
        const mid = Math.floor(a.length / 2);
        const l = ms(a.slice(0, mid));
        const r = ms(a.slice(mid));
        const res = [];
        let i = 0, j = 0;
        while (i < l.length && j < r.length) {
          if (l[i] <= r[j]) res.push(l[i++]);
          else res.push(r[j++]);
        }
        return res.concat(l.slice(i)).concat(r.slice(j));
      }
      return ms(arr);
    }
  },

  strassen: {
    id: 'strassen',
    name: 'Strassen Matrix Multiplication',
    category: 'Matrix Algebra',
    recurrence: { a: 7, b: 2, c: 2, k: 0 },
    theoreticalTime: 'O(n^2.807)',
    theoreticalSpace: 'O(n^2)',
    description: 'Computes matrix product via 7 recursive multiplications of half-sized submatrices.',
    oxcamlCode: `(* Strassen Fast Matrix Multiply in OxCaml *)
let rec strassen (a : matrix) (b : matrix) (n : int) : matrix =
  if n <= 64 then standard_multiply a b
  else
    (* 7 recursive matrix products *)
    let m1 = strassen (add a11 a22) (add b11 b22) (n/2) in
    let m2 = strassen (add a21 a22) b11 (n/2) in
    let m3 = strassen a11 (sub b12 b22) (n/2) in
    let m4 = strassen a22 (sub b21 b11) (n/2) in
    let m5 = strassen (add a11 a12) b22 (n/2) in
    let m6 = strassen (sub a21 a11) (add b11 b12) (n/2) in
    let m7 = strassen (sub a12 a22) (add b21 b22) (n/2) in
    combine_quadrants m1 m2 m3 m4 m5 m6 m7`,
    benchmarkDriver: (n) => {
      // Benchmark simulation of sub-cubic scaling
      let ops = Math.pow(n, 2.807) * 0.05;
      let sum = 0;
      for (let i = 0; i < Math.min(ops, 500000); i++) sum += (i * 3) % 7;
      return sum;
    }
  },

  binary_search: {
    id: 'binary_search',
    name: 'Binary Search',
    category: 'Searching',
    recurrence: { a: 1, b: 2, c: 0, k: 0 },
    theoreticalTime: 'O(log n)',
    theoreticalSpace: 'O(1)',
    description: 'Halves the search space at each iteration with constant work per step.',
    oxcamlCode: `(* Binary Search in OxCaml with unboxed indices *)
let rec binary_search (arr : int array) (target : int) (low : int) (high : int) : int option =
  if low > high then None
  else
    let mid = low + (high - low) / 2 in
    if arr.(mid) = target then Some mid
    else if arr.(mid) > target then binary_search arr target low (mid - 1)
    else binary_search arr target (mid + 1) high`,
    benchmarkDriver: (n) => {
      const arr = new Int32Array(n);
      for (let i = 0; i < n; i++) arr[i] = i * 2;
      const target = (n - 5) * 2;
      let low = 0, high = n - 1;
      while (low <= high) {
        const mid = (low + high) >> 1;
        if (arr[mid] === target) return mid;
        if (arr[mid] < target) low = mid + 1;
        else high = mid - 1;
      }
      return -1;
    }
  },

  cordis_ring_buffer: {
    id: 'cordis_ring_buffer',
    name: 'Cordis Zero-GC Ring Buffer',
    category: 'Cordis Streaming / Temporal',
    recurrence: { a: 1, b: 1, c: 0, k: 0 },
    theoreticalTime: 'O(1)',
    theoreticalSpace: 'O(1) [Bounded]',
    description: 'Cordis fixed-capacity circular stream buffer for deterministic low-latency updates.',
    oxcamlCode: `(* Cordis Ring Buffer in OxCaml with unique mode *)
type 'a ring_buffer = {
  data : 'a array;
  mutable head : int;
  capacity : int;
}

let push (rb : 'a ring_buffer) (item : 'a) : unit =
  rb.data.(rb.head) <- item;
  rb.head <- (rb.head + 1) mod rb.capacity`,
    benchmarkDriver: (n) => {
      const cap = 500;
      const buf = new Float64Array(cap);
      let head = 0;
      for (let i = 0; i < n; i++) {
        buf[head] = i * 1.5;
        head = (head + 1) % cap;
      }
      return buf[0];
    }
  },

  dynamic_array: {
    id: 'dynamic_array',
    name: 'Dynamic Array (Amortized Doubling)',
    category: 'Amortized Data Structures',
    recurrence: { a: 1, b: 2, c: 1, k: 0 },
    theoreticalTime: 'O(1) Amortized (O(n) worst-case)',
    theoreticalSpace: 'O(n)',
    description: 'Array doubling strategy analyzed via Physicist’s Potential Function Phi(D) = 2*size - capacity.',
    oxcamlCode: `(* Dynamic Array with doubling reallocation *)
type 'a dyn_array = {
  mutable data : 'a array;
  mutable size : int;
  mutable capacity : int;
}

let push (da : 'a dyn_array) (x : 'a) : unit =
  if da.size = da.capacity then begin
    let new_cap = da.capacity * 2 in
    let new_data = Array.make new_cap x in
    Array.blit da.data 0 new_data 0 da.size;
    da.data <- new_data;
    da.capacity <- new_cap;
  end;
  da.data.(da.size) <- x;
  da.size <- da.size + 1`,
    benchmarkDriver: (n) => {
      const arr = [];
      for (let i = 0; i < n; i++) arr.push(i);
      return arr.length;
    }
  },

  akra_bazzi_unequal: {
    id: 'akra_bazzi_unequal',
    name: 'Akra-Bazzi (1/3 + 2/3 Split)',
    category: 'Unequal Divide & Conquer',
    terms: [[1, 1/3], [1, 2/3]],
    drivingDegree: 1.0,
    theoreticalTime: 'O(n log n)',
    theoreticalSpace: 'O(log n)',
    description: 'Unequal subproblem partition T(n) = T(n/3) + T(2n/3) + n with characteristic root p = 1.',
    oxcamlCode: `(* Akra-Bazzi Asymmetric Tree in OxCaml *)
let rec akra_tree (n : int) : int =
  if n <= 1 then 1
  else
    let w1 = akra_tree (n / 3) in
    let w2 = akra_tree (2 * n / 3) in
    w1 + w2 + n`,
    benchmarkDriver: (n) => {
      function akra(sz) {
        if (sz <= 1) return 1;
        return akra(Math.floor(sz / 3)) + akra(Math.floor((2 * sz) / 3)) + sz;
      }
      return akra(Math.min(n, 50000));
    }
  }
};
