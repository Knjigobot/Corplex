/**
 * Corplex Core: Types & Asymptotic Bounds Specification
 */

export const ASYMPTOTIC_CLASSES = {
  O_CONST: 'O(1)',
  O_DOUBLE_LOG: 'O(log log n)',
  O_LOG: 'O(log n)',
  O_SQRT: 'O(sqrt(n))',
  O_LINEAR: 'O(n)',
  O_QUASILINEAR: 'O(n log n)',
  O_QUADRATIC: 'O(n^2)',
  O_CUBIC: 'O(n^3)',
  O_EXPONENTIAL: 'O(2^n)',
  O_FACTORIAL: 'O(n!)'
};

export const BOUND_COLORS = {
  'O(1)': '#00ffaa',
  'O(log log n)': '#00e5ff',
  'O(log n)': '#00b4d8',
  'O(sqrt(n))': '#70d6ff',
  'O(n)': '#ffd166',
  'O(n log n)': '#ff9f1c',
  'O(n^2)': '#ff5555',
  'O(n^3)': '#e01e37',
  'O(2^n)': '#bd93f9',
  'O(n!)': '#ff0055'
};
